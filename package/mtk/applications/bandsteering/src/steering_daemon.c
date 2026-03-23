#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <arpa/inet.h>
#include <syslog.h>

#define NETLINK_STEERING 30
#define STEERING_GROUP 1
#define MAX_PAYLOAD 1024

struct steering_event_data {
    char if_name[16];
    unsigned char sta_addr[6];
};

int main(void) {
    struct sockaddr_nl src_addr, dest_addr;
    struct nlmsghdr *nlh = NULL;
    struct iovec iov;
    struct msghdr msg;
    int sock_fd;
    int ret;

    openlog("SteeringDaemon", LOG_PID, LOG_DAEMON);

    syslog(LOG_INFO, "Starting band steering daemon");

    sock_fd = socket(PF_NETLINK, SOCK_RAW, NETLINK_STEERING);
    if (sock_fd < 0) {
        syslog(LOG_ERR, "Failed to create band steering netlink socket");
        syslog(LOG_INFO, "Stopping band steering daemon.");
        closelog();
        return -1;
    }

    memset(&src_addr, 0, sizeof(src_addr));
    src_addr.nl_family = AF_NETLINK;
    src_addr.nl_pid = getpid();
    src_addr.nl_groups = STEERING_GROUP;

    ret = bind(sock_fd, (struct sockaddr *)&src_addr, sizeof(src_addr));
    if (ret < 0) {
        syslog(LOG_ERR, "Failed to bind band steering netlink socket");
        close(sock_fd);
        syslog(LOG_INFO, "Stopping band steering daemon.");
        closelog();
        return -1;
    }

    nlh = (struct nlmsghdr *)malloc(NLMSG_SPACE(MAX_PAYLOAD));
    if (!nlh) {
        syslog(LOG_ERR, "Failed to allocate memory for band steering daemon nlh");
        close(sock_fd);
        syslog(LOG_INFO, "Stopping band steering daemon.");
        closelog();
        return -1;
    }
    
    iov.iov_base = (void *)nlh;
    iov.iov_len = NLMSG_SPACE(MAX_PAYLOAD);
    msg.msg_name = (void *)&dest_addr;
    msg.msg_namelen = sizeof(dest_addr);
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;

    syslog(LOG_INFO, "Waiting for band steering messages from kernel");

    while (1) {
        ret = recvmsg(sock_fd, &msg, 0);
        if (ret < 0) {
            syslog(LOG_ERR, "Failed to receive band steering message");
            continue;
        }

        if (NLMSG_OK(nlh, ret)) {
            struct steering_event_data *data = (struct steering_event_data *)NLMSG_DATA(nlh);
            char mac_str[18];
            char command[128];

            snprintf(mac_str, sizeof(mac_str), "%02x:%02x:%02x:%02x:%02x:%02x",
                     data->sta_addr[0], data->sta_addr[1], data->sta_addr[2],
                     data->sta_addr[3], data->sta_addr[4], data->sta_addr[5]);

            syslog(LOG_INFO, "Received band steering event: Interface=%s, STA_MAC=%s", data->if_name, mac_str);

            snprintf(command, sizeof(command), "/sbin/steeringsta %s %s", data->if_name, mac_str);
            syslog(LOG_INFO, "Executing band steering command: %s", command);

            system(command);
        }
    }

    free(nlh);
    close(sock_fd);

    syslog(LOG_INFO, "Stopping band steering daemon.");
    closelog();

    return 0;
}
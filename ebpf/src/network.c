/* Copyright (c)
 * All rights reserved
 *
 * This program and the accompanying materials are made available under the
 * terms of the Apache License, Version 2.0 which accompanies this distribution,
 * and is available at http://www.apache.org/licenses/LICENSE-2.0
 */

#include "./network.h"

#include <linux/pkt_cls.h>

int tc_pingpong(struct __sk_buff *skb) {
  void *data = (void *)(long)skb->data;
  void *data_end = (void *)(long)skb->data_end;

  if (!is_icmp_ping_request(data, data_end)) {
    return TC_ACT_OK;
  }

  bpf_trace_printk("[tc_pingpong] ingress got packet\n");

  struct iphdr *iph = data + sizeof(struct ethhdr);
  struct icmphdr *icmp = data + sizeof(struct ethhdr) + sizeof(struct iphdr);
  bpf_trace_printk("[tc_pingpong] ICMP request for %x type %x\n", iph->daddr,
                   icmp->type);

  swap_mac_addresses(skb);
  swap_ip_addresses(skb);

  // Change the type of the ICMP packet to 0 (ICMP Echo Reply) (was 8 for ICMP
  // Echo request)
  update_icmp_type(skb, 8, 0);

  // Redirecting the modified skb on the same interface to be transmitted
  // again
  bpf_clone_redirect(skb, skb->ifindex, 0);

  // We modified the packet and redirected a clone of it, so drop this one
  return TC_ACT_SHOT;
}

/* Copyright (c)
 * All rights reserved
 *
 * This program and the accompanying materials are made available under the
 * terms of the Apache License, Version 2.0 which accompanies this distribution,
 * and is available at http://www.apache.org/licenses/LICENSE-2.0
 */

#include <linux/icmp.h>
#include <linux/ip.h>

#ifndef EBPF_SRC_NETWORK_H_
#define EBPF_SRC_NETWORK_H_

static __always_inline unsigned short is_icmp_ping_request(void *data,
                                                           void *data_end) {
  struct ethhdr *eth = data;
  if (data + sizeof(struct ethhdr) > data_end)
    return 0;

  if (bpf_ntohs(eth->h_proto) != ETH_P_IP)
    return 0;

  struct iphdr *iph = data + sizeof(struct ethhdr);
  if (data + sizeof(struct ethhdr) + sizeof(struct iphdr) > data_end)
    return 0;

  if (iph->protocol != 0x01)
    // We're only interested in ICMP packets
    return 0;

  struct icmphdr *icmp = data + sizeof(struct ethhdr) + sizeof(struct iphdr);
  if (data + sizeof(struct ethhdr) + sizeof(struct iphdr) +
          sizeof(struct icmphdr) >
      data_end)
    return 0;

  return (icmp->type == 8);
}

static __always_inline void swap_mac_addresses(struct __sk_buff *skb) {
  unsigned char src_mac[6];
  unsigned char dst_mac[6];
  bpf_skb_load_bytes(skb, offsetof(struct ethhdr, h_source), src_mac, 6);
  bpf_skb_load_bytes(skb, offsetof(struct ethhdr, h_dest), dst_mac, 6);
  bpf_skb_store_bytes(skb, offsetof(struct ethhdr, h_source), dst_mac, 6, 0);
  bpf_skb_store_bytes(skb, offsetof(struct ethhdr, h_dest), src_mac, 6, 0);
}

#define IP_SRC_OFF (ETH_HLEN + offsetof(struct iphdr, saddr))
#define IP_DST_OFF (ETH_HLEN + offsetof(struct iphdr, daddr))

static __always_inline void swap_ip_addresses(struct __sk_buff *skb) {
  unsigned char src_ip[4];
  unsigned char dst_ip[4];
  bpf_skb_load_bytes(skb, IP_SRC_OFF, src_ip, 4);
  bpf_skb_load_bytes(skb, IP_DST_OFF, dst_ip, 4);
  bpf_skb_store_bytes(skb, IP_SRC_OFF, dst_ip, 4, 0);
  bpf_skb_store_bytes(skb, IP_DST_OFF, src_ip, 4, 0);
}

#define ICMP_CSUM_OFF                                                          \
  (ETH_HLEN + sizeof(struct iphdr) + offsetof(struct icmphdr, checksum))
#define ICMP_TYPE_OFF                                                          \
  (ETH_HLEN + sizeof(struct iphdr) + offsetof(struct icmphdr, type))

static __always_inline void update_icmp_type(struct __sk_buff *skb,
                                             unsigned char old_type,
                                             unsigned char new_type) {
  bpf_l4_csum_replace(skb, ICMP_CSUM_OFF, old_type, new_type, 2);
  bpf_skb_store_bytes(skb, ICMP_TYPE_OFF, &new_type, sizeof(new_type), 0);
}

#endif // EBPF_SRC_NETWORK_H_

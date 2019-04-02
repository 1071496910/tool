import urllib
import urllib2
import sys
es_service_addr = sys.argv[1]
 
url = "http://" + es_service_addr + "/_cat/indices?v";
req = urllib2.Request(url)
res_data = urllib2.urlopen(req)
res = res_data.read()
 
list = res.split('\n')
 
title = list[0].split()
length = len(list)
data = list[1:length]
map={}
for i in title:
        map[i] = title.index(i)
capacity_used = 0;
 
for i in data:
        value = i.split()
        l = len(value)
        if l > 0 :
                store_size = value[map['store.size']].lower()
                if "k" in store_size:
                        capacity_used += float(store_size[:-2]) /1024 /1024
                elif "m" in store_size:
                        capacity_used += float(store_size[:-2]) /1024
                elif "g" in store_size:
                        capacity_used += float(store_size[:-2]) 
                elif "t" in store_size:
                        capacity_used += float(store_size[:-2]) * 1024
                elif "p" in store_size:
                        capacity_used += float(store_size[:-2]) * 1024 * 1024
                else:
                        capacity_used += float(store_size[:-2]) /1024 /1024 /1024
 
print str(capacity_used) + " GB"

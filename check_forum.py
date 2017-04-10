#!/usr/bin/python
"""
Forum alert script
"""
import feedparser
from datetime import datetime

def get_keywords():
    return ["knot","kresd","unbound","schnapps","dns","dhcp","resolver","dnsmasq"]

def find_in_array(arr,title_in,date_in):
    for items in arr:
        title,link,published_date,keyword=items
        dif=date_in-published_date
        if title_in == title and dif.seconds>=0:
            arr_index= arr.index(items)
            del arr[arr_index]

def get_entries(keywords):
    d = feedparser.parse('https://forum.turris.cz/posts.rss')
    arr=[]
    for i in range(0,len(d['entries'])):
        title=d['entries'][i]['title']
        text=d['entries'][i]['summary']
        link=d['entries'][i]['link']
        published=d['entries'][i]['published']

        for keyword in keywords:
            if title.lower().find(keyword) >=0 or text.lower().find(keyword)>=0:
                date_published=datetime.strptime(" ".join(published.split()[:5]),"%a, %d %b %Y %H:%M:%S")
                find_in_array(arr,title,date_published)
                arr.append([title,link,date_published,keyword])
    return arr

def print_report():
    tmp_str=""
    for items in get_entries(get_keywords()):
        title,link,published_date,keyword=items
        dif = (datetime.now()-published_date)
        info = (title[:15] + '...') if len(title) > 15 else title
        if dif.days==0:
            tmp_str+="# %s (%s) (Updated today) - Keyword:%s\n" % (info,link,keyword)
        elif dif.days==1:
            tmp_str+="# %s (%s) (Updated %i day ago) - Keyword:%s\n" % (info,link,dif.days,keyword)
        else:
            tmp_str+="# %s (%s) (Updated %i days ago) - Keyword:%s\n" % (info,link,dif.days,keyword)

    print ''.join([i if ord(i) < 128 else ' ' for i in tmp_str])

print_report()

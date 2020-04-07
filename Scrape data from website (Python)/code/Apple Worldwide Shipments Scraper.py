# -*- coding: utf-8 -*-
"""
Created on Tue Nov  5 16:30:39 2019

@author: azhu
"""

##############################################
import math 
from selenium import webdriver
from selenium.webdriver import ActionChains
from selenium.webdriver import TouchActions
#from selenium import Point
from time import sleep
from bs4 import BeautifulSoup
import re
import pandas as pd
import time 
import numpy as np
import datetime
import urllib
import webbrowser
import requests

###########################################################
# option1: import html downloaded frm webpage
#html = open(r'P:\Python Development\Data Scraping\programming\webscaping\downloaded HTML\Apple iPhone smartphone shipments worldwide 2010-2019 _ Statista.html')
# option2: using request to import html 
page = requests.get("https://www.statista.com/statistics/299153/apple-smartphone-shipments-worldwide/")
chart = BeautifulSoup(page.content, "html.parser").find('tbody', {'role': "alert"})
tr = chart.findAll('tr')
table = pd.DataFrame()
for i in tr:
    tr = i.findAll('td')
    table = table.append(pd.DataFrame({'quarter': tr[0].text, 'shipment': tr[1].text}, index=[0]), 
                         ignore_index = True)

table.to_csv(r'\...\Apple worldwide shipments.csv', index = False) 

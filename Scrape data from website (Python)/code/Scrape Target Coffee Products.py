# -*- coding: utf-8 -*-
"""
Created on Fri Jan  3 16:47:58 2020

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
###########################################################
# specify path to chrome driver
chromepath = r"\...\chromedriver.exe"
chromeoptions = webdriver.ChromeOptions()
driver = webdriver.Chrome(executable_path=chromepath, chrome_options=chromeoptions)
###########################################################
    
def scraper(string):
    url = 'https://www.target.com/'
    driver.get(url)
    sleep(1)
    inputElement = driver.find_element_by_xpath(r'//*[@id="search"]')
    inputElement.send_keys(string)
    inputElement.submit() 
    sleep(3)
    page = int(driver.find_element_by_xpath("//*[contains(text(), 'page 1 of')]").text.replace('page 1 of ', ''))
    
    master = pd.DataFrame(columns=['product', 'upc'])
    count = 1
    for p in range(page):
        driver.get(r'https://www.target.com/s?searchTerm={}&Nao={}'.format(string.replace(' ', '+'), p*24))
        sleep(3)    
        soup = BeautifulSoup(driver.page_source, "html.parser")
        regex = re.compile('\/p\/')
        text = soup.findAll('a', {'href': regex})
        hrefs = []
        # using list comprehension
        [hrefs.append(x['href']) for x in text if x['href'] not in hrefs]
           
        for href in hrefs:
            prod_url = 'https://www.target.com' + href
            driver.get(prod_url)
            sleep(3)
            try:
                soup = BeautifulSoup(driver.page_source, "html.parser")
                upc = soup.find(text = re.compile('UPC')).find_parent('div').text
                product = soup.find('title').text
                record = pd.DataFrame({'product': product , 'upc': upc}, index=[0])
                if upc not in master['upc'].tolist():        
                    master = master.append(record, ignore_index = True)          
            except:
                continue
            print(count)
            count += 1
    return master
        
########################################################### 
# search all coffee related products in Target       
search = scraper('k-cup pods')                 
master = search.drop_duplicates()

master.to_csv(r'\...\Target Coffee Products.csv', index = False, encoding="utf-8-sig")









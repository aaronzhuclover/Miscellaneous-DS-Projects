# -*- coding: utf-8 -*-
"""
Created on 8/29/2019
author: A Zhu
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
chromepath = r"C:\Users\azhu\Desktop\mis\Python Development\Chromedriver\chromedriver.exe"
chromeoptions = webdriver.ChromeOptions()
driver = webdriver.Chrome(executable_path=chromepath)
##############################################
# extract list of DRAM modules
# import DRAM modules speed
module = pd.read_excel(r'\...\DRAM Module Types.xlsx')
module_speed = module.Speed
module_list = []
for ms in module_speed:
    url = 'https://keepa.com'
    driver.get(url)
    sleep(5)
    driver.find_element_by_xpath(r'//*[@id="menuSearch"]').click()
    inputElement = driver.find_element_by_xpath(r'//*[@id="searchInput"]')
    inputElement.send_keys(ms)
    inputElement.submit() 
    sleep(7)
    
    # move mouse to products window
    target = driver.find_element_by_xpath(r'//*[@id="grid-search"]/div/div[2]/div[1]/div[3]')
    target.click()
    actions = ActionChains(driver)
    actions.reset_actions()
    actions.move_to_element(target)
    actions.perform()
    
    # scrape ASIN codes
    sleep(3)
    soup = BeautifulSoup(driver.page_source, "html.parser")
    container = soup.find('div', {'class': "ag-center-cols-container"})
    asin = container.findAll('div', {'col-id': 'asin'})
    initial_list = []
    for i in asin:
        print(i.text)
        initial_list.append(i.text) 
    master_list = initial_list        
    position = 104*5
    while (True):  
        print(position)
        driver.execute_script("arguments[0].scrollTop = {}".format(position), target)
        sleep(2)
        soup = BeautifulSoup(driver.page_source, "html.parser")
        container = soup.find('div', {'class': "ag-center-cols-container"})
        asin = container.findAll('div', {'col-id': 'asin'})
        asin_list = []
        for i in asin:
            print(i.text)
            asin_list.append(i.text)    
        if(asin_list == initial_list):
            break 
        else:
            initial_list = asin_list
            master_list = master_list + asin_list
            position = position + 104*5        
    master_list = np.unique(master_list).tolist()
    module_list = module_list + master_list

module_list = np.unique(module_list).tolist()
pd.DataFrame(module_list).to_csv(r'\...\DRAM Module.csv', index = False, encoding="utf-8-sig")
##############################################################
# extract historial prices for DRAM modules
module_list = pd.read_csv(r'\...\DRAM Module.csv')
module_list = module_list.iloc[:,0]

###############

data_m = []
debug = 0 
for m in module_list[debug:module_list.size]:
    print(m)
    print(datetime.datetime.now())
    try:
        url = 'https://keepa.com/#!product/1-{}'.format(m)
        driver.get(url)
        sleep(5)
           
        # expand time range 
        driver.find_element_by_xpath('//*[contains(text(), "All (")]').click()
    
        sleep(1)
        soup = BeautifulSoup(driver.page_source, "html.parser") 
        # extract first ticklable to create time 
        tickLabel     = soup.find('div', {'class': "tickLabel"}).text
        # extract product name 
        product_name  = soup.find('div', {'class': "productTableDescriptionTitle"}).text
        # extract product brand
        product_brand = soup.find('div', {'class': "productTableDescriptionBrand"}).text
        
        # check New/List Price/Amazon
        legendTable = soup.find('table', {'class': "legendTable"}).findAll('tr')
        click_new = 0 
        click_amazon = 0 
        click_list_price = 0 
        
        # find position of New/List Price/Amazon
        position_new = 0 
        position_amazon = 0 
        position_list_price = 0
        incr_new = 1
        incr_amazon = 1
        incr_list_price = 1
        
        for t in legendTable:
            if incr_new == 1:
                position_new +=1
            if incr_amazon == 1:
                position_amazon +=1
            if incr_list_price == 1:
                position_list_price +=1    
            if (str(t).find('>New<')>0):
                incr_new = 0
            elif (str(t).find('>Amazon<')>0):
                incr_amazon = 0
            elif (str(t).find('>List Price<')>0):
                incr_list_price = 0        
            if (str(t).find('>New<')>0) & (str(t).find('1px')>0):
                click_new = 1
            elif (str(t).find('>Amazon<')>0) & (str(t).find('1px')>0):
                click_amazon = 1
            elif (str(t).find('>List Price<')>0) & (str(t).find('1px')>0):
                click_list_price = 1
            
        # Check Amazon
        if (click_amazon == 1):
            driver.find_element_by_xpath('//*[@id="graph"]/div[1]/table/tbody/tr[{}]/td[1]'.format(position_amazon)).click()   
        # Check New   
        if (click_new == 1):
            driver.find_element_by_xpath('//*[@id="graph"]/div[1]/table/tbody/tr[{}]/td[1]'.format(position_new)).click()
        # Check list price
        if (click_list_price == 1):
            driver.find_element_by_xpath('//*[@id="graph"]/div[1]/table/tbody/tr[{}]/td[1]'.format(position_list_price)).click()            
        
        # move mouse to the center of price graph 
        target = driver.find_element_by_xpath(r"//*[@id='graph']/canvas[2]")
        target.location
        target.size
        
        actions = ActionChains(driver)
        actions.reset_actions()
        actions.move_to_element(target)
        actions.move_by_offset(math.floor(target.size['width']/2)*-1, 0)
        actions.perform()
        
        master = []
        for x in range(math.floor(target.size['width']/1)):
            actions.reset_actions()
            actions.move_by_offset(1, 0)
            actions.perform()
            
            soup = BeautifulSoup(driver.page_source, "html.parser")
            
         # scrape prices
        price_tag = soup.findAll('div',{'class': "flotTip"})
        price = []
        for x in price_tag:
            if (x.text != "") & (str(x).find('display: block')>0):
                price.append(x.text)
        price = ', '.join(price) 
        # scrape date
        if price != '':
            date = soup.find('div',{'id': "flotTipDate"}).text
            data = pd.DataFrame({ 'price': price,
                                  'date': date,
                                  'first_ticklabel': tickLabel,
                                  'product_name': product_name,
                                  'product_brand': product_brand,
                                  'asin': 'B06XPJC1V5'
                    }, index=[0])
            master.append(data)
        
        df = pd.concat(master, ignore_index=True)
        df = df.drop_duplicates()
        data_m.append(df)
        debug +=1
    except:
        debug +=1
        continue 


##############################
data_out = pd.concat(data_m, ignore_index=True)

data_out.to_csv(r'\...\DRAM Module Prices.csv', index = False, encoding="utf-8-sig")








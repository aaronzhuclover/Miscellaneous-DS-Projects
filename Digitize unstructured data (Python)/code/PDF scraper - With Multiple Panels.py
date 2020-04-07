# -*- coding: utf-8 -*-
"""
Created on 12/20/2019

@author: Azhu
"""

import glob
import pdfquery
import os
import tabula as tb
import cv2
import numpy as np
import pandas as pd
import PyPDF2
from PyPDF2 import PdfFileReader, PdfFileWriter

########################################################################################
# define a scraping function    
def pdfscrape(pdf):
    # extract year 
    label =  pdf.pq('LTTextLineHorizontal:contains("{}")'.format("Tax Statement") ) 
    year = pd.DataFrame()
    for i in range(len(label)):
        x0 = float(label[i].get('x1',0)) + 5
        y0 = float(label[i].get('y1',0)) + 1
        x1 = float(label[i].get('x1',0)) + 30
        y1 = float(label[i].get('y1',0)) + 2 
        if (x0<300) & (x1<300) & (y0>440) & (y1>440):       
            loc = 1
        elif (x0>300) & (x1>300) & (y0>440) & (y1>440):       
            loc = 2   
        elif (x0<300) & (x1<300) & (y0<440) & (y1<440):       
            loc = 3   
        elif (x0>300) & (x1>300) & (y0<440) & (y1<440):       
            loc = 4       
        year_str = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x0, y0, x1, y1)).text()
        record = pd.DataFrame({'loc': loc, 'year': year_str}, index=[0])     
        year = year.append(record, ignore_index = True)
    
    # extract ssn
    label = pdf.pq('LTTextLineHorizontal:contains("a Employee")') 
    ssn = pd.DataFrame()
    for i in range(len(label)):
        x0 = float(label[i].get('x0',0))
        y0 = float(label[i].get('y0',0)) - 15
        x1 = float(label[i].get('x1',0))
        y1 = float(label[i].get('y0',0)) - 1
        
        if str(label[i].layout).find('SSN')>0:
            if (x0<300) & (x1<300) & (y0>440) & (y1>440):       
                loc = 1
            elif (x0>300) & (x1>300) & (y0>440) & (y1>440):       
                loc = 2   
            elif (x0<300) & (x1<300) & (y0<440) & (y1<440):       
                loc = 3   
            elif (x0>300) & (x1>300) & (y0<440) & (y1<440):       
                loc = 4            
            ssn_str = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x0, y0, x1, y1)).text()
            record = pd.DataFrame({'loc': loc, 'ssn': ssn_str}, index=[0])     
            ssn = ssn.append(record, ignore_index = True)
        else:
            continue
        
    # extract employer 
    label =  pdf.pq('LTTextLineHorizontal:contains("{}")'.format("d Control") )   
    employer = pd.DataFrame()
    for i in range(len(label)):
        x0 = float(label[i].get('x0',0))
        y0 = float(label[i].get('y1',0)) + 2
        x1 = float(label[i].get('x1',0)) 
        y1 = float(label[i].get('y1',0)) + 40 
        if (x0<300) & (x1<300) & (y0>440) & (y1>440):       
            loc = 1
        elif (x0>300) & (x1>300) & (y0>440) & (y1>440):       
            loc = 2   
        elif (x0<300) & (x1<300) & (y0<440) & (y1<440):       
            loc = 3   
        elif (x0>300) & (x1>300) & (y0<440) & (y1<440):       
            loc = 4       
        employer_str = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x0, y0, x1, y1)).text()
        record = pd.DataFrame({'loc': loc, 'employer': employer_str}, index=[0])     
        employer = employer.append(record, ignore_index = True)
        
    # extract control_number 
    label =  pdf.pq('LTTextLineHorizontal:contains("d Control")')   
    control_number = pd.DataFrame()
    for i in range(len(label)):
        x0 = float(label[i].get('x0',0))
        y0 = float(label[i].get('y0',0)) - 6
        x1 = float(label[i].get('x1',0)) + 30
        y1 = float(label[i].get('y0',0)) - 1    
        if (x0<300) & (x1<300) & (y0>440) & (y1>440):       
            loc = 1
        elif (x0>300) & (x1>300) & (y0>440) & (y1>440):       
            loc = 2   
        elif (x0<300) & (x1<300) & (y0<440) & (y1<440):       
            loc = 3   
        elif (x0>300) & (x1>300) & (y0<440) & (y1<440):       
            loc = 4       
        control_number_str = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x0, y0, x1, y1)).text()
        record = pd.DataFrame({'loc': loc, 'control_number': control_number_str}, index=[0])     
        control_number = control_number.append(record, ignore_index = True)
            
    # extract employee_name 
    label =  pdf.pq('LTTextLineHorizontal:contains("{}")'.format("Employee's name") )    
    employee_name = pd.DataFrame()
    for i in range(len(label)):
        x0 = float(label[i].get('x0',0))
        y0 = float(label[i].get('y0',0)) - 6
        x1 = float(label[i].get('x1',0)) 
        y1 = float(label[i].get('y0',0)) - 1        
        if (x0<300) & (x1<300) & (y0>440) & (y1>440):       
            loc = 1
        elif (x0>300) & (x1>300) & (y0>440) & (y1>440):       
            loc = 2   
        elif (x0<300) & (x1<300) & (y0<440) & (y1<440):       
            loc = 3   
        elif (x0>300) & (x1>300) & (y0<440) & (y1<440):       
            loc = 4       
        employee_name_str = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x0, y0, x1, y1)).text()
        record = pd.DataFrame({'loc': loc, 'employee_name': employee_name_str}, index=[0])     
        employee_name = employee_name.append(record, ignore_index = True)
    
    # extract employee_address 
    label =  pdf.pq('LTTextLineHorizontal:contains("{}")'.format("Employee's name") )    
    employee_address = pd.DataFrame()
    for i in range(len(label)):
        x0 = float(label[i].get('x0',0))
        y0 = float(label[i].get('y0',0)) - 40
        x1 = float(label[i].get('x1',0)) 
        y1 = float(label[i].get('y0',0)) - 10
        if (x0<300) & (x1<300) & (y0>440) & (y1>440):       
            loc = 1
        elif (x0>300) & (x1>300) & (y0>440) & (y1>440):       
            loc = 2   
        elif (x0<300) & (x1<300) & (y0<440) & (y1<440):       
            loc = 3   
        elif (x0>300) & (x1>300) & (y0<440) & (y1<440):       
            loc = 4   
        
        employee_address_raw    = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x0, y0, x1, y1))
        employee_address_str = ''
        for sub in employee_address_raw:
            employee_address_str = employee_address_str + " | " + sub.text
        employee_address_str = employee_address_str.replace(' | ', '', 1)
        
        record = pd.DataFrame({'loc': loc, 'employee_address': employee_address_str}, index=[0])     
        employee_address = employee_address.append(record, ignore_index = True)
    
    # extract medicare_wage_tip
    label =  pdf.pq('LTTextLineHorizontal:contains("{}")'.format("Medicare wages") )    
    medicare_wage_tip = pd.DataFrame()
    for i in range(len(label)):
        x0 = float(label[i].get('x0',0))
        y0 = float(label[i].get('y0',0)) - 6
        x1 = float(label[i].get('x1',0)) 
        y1 = float(label[i].get('y0',0)) - 1
        if (x0<300) & (x1<300) & (y0>440) & (y1>440):       
            loc = 1
        elif (x0>300) & (x1>300) & (y0>440) & (y1>440):       
            loc = 2   
        elif (x0<300) & (x1<300) & (y0<440) & (y1<440):       
            loc = 3   
        elif (x0>300) & (x1>300) & (y0<440) & (y1<440):       
            loc = 4       
        medicare_wage_tip_str = pdf.pq('LTTextLineHorizontal:overlaps_bbox("%s, %s, %s, %s")' % (x0, y0, x1, y1)).text()
        record = pd.DataFrame({'loc': loc, 'medicare_wage_tip': medicare_wage_tip_str}, index=[0])     
        medicare_wage_tip = medicare_wage_tip.append(record, ignore_index = True)
    
    page = pd.merge(year, ssn, on = 'loc', how='outer')
    page = pd.merge(page, employer, on = 'loc', how='outer')
    page = pd.merge(page, control_number, on = 'loc', how='outer')
    page = pd.merge(page, employee_name, on = 'loc', how='outer')
    page = pd.merge(page, employee_address, on = 'loc', how='outer')
    page = pd.merge(page, medicare_wage_tip, on = 'loc', how='outer')
    return(page)


        
########################################################################################
# import file_1 - file_5
files = ['file_1', 'file_2', 'file_3', 'file_4', 'file_5']
for f in files:   
    print(f)
    file = r'\...\{}_image.pdf'.format(f)
    
    bundled = PdfFileReader(file)
    page_count = bundled.getNumPages()
    master = pd.DataFrame()
    for p in range(page_count):
        print('{}: page_{}'.format(f, p))
        current_page = bundled.getPage(p)
        pdf_writer = PdfFileWriter()
        pdf_writer.addPage(current_page)
        tempfile = r'\...\temp.pdf'
        with open(tempfile, "wb") as out:
            pdf_writer.write(out)
        pdf = pdfquery.PDFQuery(tempfile)
        pdf.load(0)
        label =  pdf.pq('LTTextLineHorizontal:contains("{}")'.format("Copy D") ) 
        if len(label)> 0:
            try:
                page = pdfscrape(pdf) 
                page['page'] = p + 1
                page['source'] = f
                master = master.append(page, ignore_index = True)
            except:
                continue
    master.to_csv(r'\...\W2_Data_{}.csv'.format(f), index = False) 

















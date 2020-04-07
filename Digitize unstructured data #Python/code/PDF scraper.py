# -*- coding: utf-8 -*-
"""
Created on 10/1/2019

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

############################################
# define a scraping function
def pdfscrape(pdf):
    year                    = pdf.pq('LTTextLineHorizontal:overlaps_bbox("260, 425,  370, 460")').text()
    ssn                     = pdf.pq('LTTextLineHorizontal:overlaps_bbox("195, 735,  243, 745")').text()
    ein                     = pdf.pq('LTTextLineHorizontal:overlaps_bbox("48,  710,  92,  721")').text()
    employer_name           = pdf.pq('LTTextLineHorizontal:overlaps_bbox("48,  686,  300, 696")').text()
    employer_address        = pdf.pq('LTTextLineHorizontal:overlaps_bbox("48,  649,  300, 684")').text()
    control_number          = pdf.pq('LTTextLineHorizontal:overlaps_bbox("48,  615,  97,  626")').text()
    first_name              = pdf.pq('LTTextLineHorizontal:overlaps_bbox("48,  590,  150, 601")').text()
    last_name               = pdf.pq('LTTextLineHorizontal:overlaps_bbox("175, 590,  280, 601")').text()
    employee_address        = pdf.pq('LTTextLineHorizontal:overlaps_bbox("48,  543,  260, 577")').text()
    medicare_wage_tip       = pdf.pq('LTTextLineHorizontal:overlaps_bbox("370, 662,  430, 672")').text()
    
    page = pd.DataFrame({'year': year,
                         'ssn': ssn,
                         'ein': ein,
                         'employer_name': employer_name,
                         'employer_address': employer_address,
                         'control_number': control_number,
                         'first_name': first_name,
                         'last_name': last_name,
                         'employee_address': employee_address,
                         'medicare_wage_tip': medicare_wage_tip
                       }, index=[0])
    return(page)

############################################
# import Pdf files
file = r'\...\sample.pdf'
pdf = pdfquery.PDFQuery(file)
pagecount = pdf.doc.catalog['Pages'].resolve()['Count']

master = []
for p in range(pagecount):
    pdf.load(p)
    page = pdfscrape(pdf) 
    page['source'] = 'W2 Data'
    master.append(page)
    
df = pd.concat(master, ignore_index=True)
df.to_csv(r'...\sample.csv', index = False)

############################################







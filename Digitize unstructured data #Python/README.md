# Digitize Unstructured Data

<p>Python has several libraries (e.g. PyPDF2, tabula, etc.) that can deal with PDF files. In this section, Python library, “pdfquery” will be used to demonstrate how to import PDF files and convert unstructured data to structured data in Python.</p>

<img src="https://github.com/aaronzhuclover/master/blob/master/Digitize unstructured data/images/image1.PNG" height="400"/>

<p>In following example, this PDF file includes unstructured W2 data, in which we don’t have row-column structure. Relevant information (e.g., employee’s SSN, name, address, employer, wage, etc.) are scattered all over in this W2 form.</p>

<img src="https://github.com/aaronzhuclover/master/blob/master/Digitize unstructured data/images/image2.PNG" height="400"/>

<p>In the first step, we need to convert PDF into Extensible Markup Language (XML), which includes data and metadata of a given PDF page.</p>

<img src="https://github.com/aaronzhuclover/master/blob/master/Digitize unstructured data/images/image3.PNG" height="400"/>

<p>XML defines a set of rules for encoding PDF in a format that is both human-readable and machine-readable. Following is a snippet of XML for employee’s SSN. It includes both data (XXX-XX-9860) and metadata (e.g., text box coordination, height, width, etc.)</p>

<img src="https://github.com/aaronzhuclover/master/blob/master/Digitize unstructured data/images/image4.PNG" height="400"/>

<p>When you want to extract an element in a PDF, you should think about the page and the element location in terms of X-Y coordinates. The X-axis spans the width of the PDF page and the Y-axis spans the height of the page. Every element has its bounds defined by a bounding box which consists of 4 coordinates. These coordinates (X0, Y0, X1, Y1) represent left, bottom, right and top of the text box, which would give us the location of information we are interested in the PDF page. In following example, coordination [195, 735, 243, 745] indicates employee’s SSN (XXX-XX-9860) and [370, 662, 430, 672] indicates wage (34661.45). </p>

<img src="https://github.com/aaronzhuclover/master/blob/master/Digitize unstructured data/images/image5.PNG" height="400"/>

<p>We can extract each piece of relevant information individually using their corresponding text box coordination, and then combined all scraped information into single observation.</p>

<img src="https://github.com/aaronzhuclover/master/blob/master/Digitize unstructured data/images/image6.PNG" height="400"/>

<p>Information in subsequent pages/documents should not always be bounded in text boxes with the same coordinates as the first page/document. For example, length of home address varies from employee to employee so that, the coordinates of home address should be different from page to page. To overcome this issue, “pdfquery” allows us to use option, “LTTextLineHorizontal:overlaps_bbox(X0, Y0, X1, Y1)”. As soon as the text box (X0, Y0, X1, Y1) we specify initially overlaps the text boxes in subsequent page, we should extract the correct information in all pages. For example, the text box [370, 662, 430, 672] overlaps all the text boxes for SSN in a PDF. </p>

<p>Once we correctly define the all text box coordinates, we should automate this process with the use of for loop and combine rows of observations into a data table. Now we’ve constructed a structured data table from an unstructured PDF file.</p>

<img src="https://github.com/aaronzhuclover/master/blob/master/Digitize unstructured data/images/image7.PNG" height="400"/>

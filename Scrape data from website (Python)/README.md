# Scrape data from website using Python

<p>Many companies and government agencies keep records online.  Price listings, employee directories, historic data (with the use of the internet archive), charts and graphics, file repositories, data in nearly any format can be scraped from the web and turned into a useful dataset.</p>
<p>Python has some useful libraries (Selenium and BeautifulSoup) that we can use for navigating and scraping websites.</p>
<p>Selenium is a framework that controls the browser interactions programmatically such as clicks, form submissions and mouse movement. In addition, selenium comes in handy when scraping data from JavaScript generated contents in a webpage. </p>
<p>BeautifulSoup is a Python library for parsing HTML, XML and other markup languages. If a webpage display data relevant to your project, such as, table, price, date or address, but that don’t provide a directly way of downloading the data. BeautifulSoup can help you parse specific content from a webpage, remove the HTML markup and save the information.</p>
<p>Following is what a typical website looks like. Within this given webpage, we might only be interested in some components. In this example, we are most interested in the bar chart for Apple worldwide shipments.</p>

<img src="https://github.com/aaronzhuclover/master/blob/master/Scrape data from website (Python)/images/image1.PNG" height="400"/>

<p>In the first step, we need to extract HTML (HyperText Markup Language) from a webpage. We can download pages using the Python requests library. The requests library will make a GET request to a web server, which downloads the HTML contents. </p>

<img src="https://github.com/aaronzhuclover/master/blob/master/Scrape data from website (Python)/images/image2.PNG" height="400"/>

<p>HTML uses “makeup” to annotate text, images and other content for display in a Web browser. HTML markup includes special “elements”, such as, <head>, <title>, <div>, <tr>, <td> and many others. Following is a snippet of HTML script for bar chart. In the following example, it includes both data (quarter and iPhone shipments) and HTML markup elements (<tr>, <td>), which we can consider them as row and column in a structured data.</p>

<img src="https://github.com/aaronzhuclover/master/blob/master/Scrape data from website (Python)/images/image3.PNG" height="400"/>

<p>In the next step, we can use BeautifulSoup functions, such as, “find” and “findAll” to parse and clean the relevant content in the HTML by specifying the attribute of these contents. In this example, our data is included within <tboday> and has attribute of “role” equal to “alert”.</p>
<p>Another Python library, Pandas can also come in handy for data manipulation and creating a analysis-ready structure data.</p>

<img src="https://github.com/aaronzhuclover/master/blob/master/Scrape data from website (Python)/images/image4.PNG" height="400"/>

<p>With the power of Python libraries (Selenium and BeautifulSoup), we can also scrape historal product prices listed on Amazon from keepa.com and scrape all the coffee products sold by Target.</p>

<img src="https://github.com/aaronzhuclover/master/blob/master/Scrape data from website (Python)/images/image5.PNG" height="400"/>
<img src="https://github.com/aaronzhuclover/master/blob/master/Scrape data from website (Python)/images/image6.PNG" height="400"/>












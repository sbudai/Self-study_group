from datetime import datetime
import pandas as pd
from pandas_datareader import data as dreader
from datetime import datetime, timedelta
import sys
import os
os.chdir("/home/sbudai/Documents/workspace_R/R_scripts/Self-study_group/NYSE_Nasdaq_20170227/stock_analysis/data")
eleres =sys.argv[1]
kezdeti_datum= sys.argv[2]
veg_datum= sys.argv[3]


d= pd.read_csv('http://www.nasdaq.com/screening/companies-by-name.aspx?letter=0&exchange=nasdaq&render=download').append(pd.read_csv('http://www.nasdaq.com/screening/companies-by-name.aspx?letter=0&exchange=nyse&render=download')).reset_index(drop=True) 
a=list(set(d[d.Symbol.str.contains("\\^")==False].Symbol))
print (len(a))

def f(each_code):
   
    try:
        print(each_code)
        b = dreader.DataReader(each_code,'yahoo',kezdeti_datum, veg_datum)
        b['ticker']= each_code
        b.to_csv(each_code+'.csv')
    except:
        pass

from multiprocessing import Pool
p = Pool(8)
p.map(f, a)

# sql-customer-segmentation-rfm
Segmenting a customer database using SQL and the RFM model (Recency, Frequency, Monetary) to identify 'Champions', 'At Risk', and 'Lost' customers.

Part 2. Segment Exploration

‘Others’ = 39577 – 39,58% of the total
‘Potential Loyalist’ = 21437 – 21,44% of the total
‘Need Attention’ = 10929 – 10.93% of the total
‘Loyal’ = 9597 – 9.60% of the total
‘At Risk’ = 9492 – 9.49% of the total
‘Champions’ = 8964 – 8.96% of the total 

‘Others’ segment represent the core of average customers, hence the core of the business. Those customers are the one that keeps the business alive, they do not bring high revenue but at the same time they do not pose a risk. 
‘Potential Loyalist’ are a big part too, indicating a good number of recent purchases.
The rest are equally distributed. ‘Champions’ segment is the smallest but the most valuable at the same time.

‘At Risk’ = 75573125101.58 – 33.32% of the total
‘Potential Loyalist’ = 70798318934.58 – 31.21% of the total
‘Others’ = 29573640890.98 – 13.04% of the total
‘Loyal’ = 20851020863.65 – 9.19% of the total
‘Need Attention’ = 18216348949.23 – 8.03% of the total
‘Champions’ = 11816851707.44 – 5.21% of the total

‘At Risk’ is on top of the list which can be alarming, but the good news is that ‘Potential Loyalist’ balance the situation. But it is something that definitely needs extra attention.

1. Customer#000011123, India, 1325390.61 total revenue
2. Customer#000143372, Mozambique, 1325155.59 total revenue
3. Customer#000125651, Kenia, 1324971.40 total revenue
4. Customer#000047849, China, 1324523.29 total revenue
5. Customer#000108359, Jordan, 1324045.28 total revenue

The value of total revenue are quite close between the top 5 High Value Customers, it is a tight win for the first one.

Romania takes the first place, followed by Indonesia and Mozambique.
Part 3. Written Insights

RFM Scoring and Segmentation Approach

RFM is a commonly used technique that evaluates customers values and segmenting customers that can be used to build marketing strategies. 

The metrics that I used in order to have a customers rank are three:
Recency: How recently a customer bought an item
Frequency: How often a customer buys
Monetary: How much a customer spent
In order to be able to create a customer's rank I used the NTILE(5) function. That way I created 5 equally distributed ranks where 1 is the lowest metric and 5 the highest. 
Most precisely the top 20% gets a score of 5, the lowest 20% gets a score of 1. 
The OVER(ORDER BY), combined with the NTILE function, is vital in order to avoid syntax error and to perform the right ranking required by the RFM model. 
I used the CASE statement finally to create labels that transform the score into an actionable group like ‘Champions’ or ‘Need Attention’. Makes it easier to read and more comprehensible. 

Key RFM Driver

Based on my analysis on the result of my query, I would say that Recency is the most significant key to understanding customers behavior, hence building a more successful marketing strategy.  
A customer that bought in the last few days is more likely to buy again in the near future compared to customers that did not make any purchase in the last 5 years, even if it was a high profile purchase. In that sense both Frequency and Monetary lose a little of their power because it is through Recency that a potential behaviour can be predicted. 

Segment Distribution Insights

A good segment distribution can help a company to create specific marketing strategies depending on what kind of segment they are targeting. 
It is quite easy to understand that the more ‘Champions’ a company has, the healthier the company would be. It is important, in that sense, to find a way to keep those ‘Champions’ as long as possible. 
But the strategy must be different when a company faces ‘At Risk’ or ‘Lost’ segments. The analysis about why those customers are slipping away must go deeper on the cause, a major retention problem must be addressed.
An even different approach must be considered when it comes to ‘Loyal’ or ‘Potential Loyalist’. 
Therefore a healthy company cannot rely on a single strategy; developing tailored strategies would increase the chances of success. 

Strategic Recommendations

I would focus especially on the ‘Potential Loyalist’ segment: since they recently purchased, they would be more inclined and reactive to a tailored marketing campaign.
‘Champions’ and ‘Loyal’ represent the most important part for a company's revenue, for that reason they cannot be forgotten and it is important to make them feel important. A tailored discount campaign could be a very effective strategy for those segments. 
On the other hand, ‘At risk’ and ‘Lost’ are not worth spending money on targeting campaigns since they most likely already jumped out of the boat, especially when f_score (Frequency) and r_score (Recency) have values <=1.
For the ‘Need Attention’ segment it would instead be worth spending some money before it is too late. Most of the time customers find better alternatives, finding the reason why they are slipping away (they found more convenient offers for example) could be a key to win them back.

Further Analysis

An additional analysis that could be performed is to dig deep into each segment. Not only to value ‘Champions’ and ‘Loyal’ but to see, for example, what kind of subscription those segments have (if the company is offering some kind of subscription like ‘premium’ or ‘basic’). And if they do not have one then it could be a good suggestion to create them, to be able to increase the level of loyalty.
In addition, it could be a good idea to analyse what kind of products those segments buy the most and tailor specific promotions to maximise the profit from each group. 
Another idea could be to keep track, daily if it is possible, of how many customers move between the segments. That way a company can verify the success or failure of retention campaigns. Keeping an extra eye of churns in the most valuable segments

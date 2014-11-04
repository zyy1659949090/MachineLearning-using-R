#https://sites.google.com/site/miningtwitter/questions/sentiment/sentiment
#http://stackoverflow.com/questions/15194436/is-there-any-other-package-other-than-sentiment-to-do-sentiment-analysis-in-r

install.packages("C:/Users/achoudhary/Downloads/Rstem_0.4-1.zip", repos = NULL, type="source")

install.packages("Rstem", repos = "http://www.omegahat.org/R", type="source")
download.file("http://cran.r-project.org/src/contrib/Archive/sentiment/sentiment_0.2.tar.gz", "sentiment.tar.gz")
install.packages("sentiment.tar.gz", repos=NULL, type="source")
library(sentiment)

library(twitteR)
library(plyr)
library(ggplot2)
library(wordcloud)
library(RColorBrewer)
library(stringr)


reqURL <- "https://api.twitter.com/oauth/request_token"
accessURL <- "https://api.twitter.com/oauth/access_token"
authURL <- "https://api.twitter.com/oauth/authorize"

apiKey <-  "MIgAEnO0XHTPKdMv3qiGKr6nu"
apiSecret <- "CMYO2quM7fUzcVuvx8JjALiKjC9cnpXeJFqQLtv2pnECJCCZKz"
access_token <- "69009666-XkI1bcxXtE4qXfOtbRYCgkiJJvpCfsmS0fq4OSq9d"
access_token_secret <- "w89WtxJDAwakPToMqoFtpQYJIfht6YS3a8136hpcyW7eG"

setup_twitter_oauth(apiKey,apiSecret,access_token,access_token_secret)

#fetch tweets
nexus = searchTwitter("#websummit", n=2500)

# get the text
nexus = sapply(nexus, function(x) x$getText())
#Avoid the non utf-8 characters
nexus=str_replace_all(nexus,"[^[:graph:]]", " ") 


#Copy paste of direct cleaning of String
#based on general

# remove retweet entities
nexus = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", some_txt)
# remove at people
nexus = gsub("@\\w+", "", some_txt)
# remove punctuation
nexus = gsub("[[:punct:]]", "", nexus)
# remove numbers
nexus = gsub("[[:digit:]]", "", nexus)
# remove html links
nexus = gsub("http\\w+", "", nexus)
# remove unnecessary spaces
nexus = gsub("[ \t]{2,}", "", nexus)
nexus = gsub("^\\s+|\\s+$", "", nexus)

# define "tolower error handling" function 
try.error = function(x)
{
  # create missing value
  y = NA
  # tryCatch error
  try_error = tryCatch(tolower(x), error=function(e) e)
  # if not an error
  if (!inherits(try_error, "error"))
    y = tolower(x)
  # result
  return(y)
}
# lower case using try.error with sapply 
nexus = sapply(nexus, try.error)

# remove NAs in some_txt
nexus = nexus[!is.na(nexus)]
names(nexus) = NULL




# classify emotion
class_emo = classify_emotion(nexus, algorithm="bayes", prior=1.0)
# get emotion best fit
emotion = class_emo[,7]
# substitute NA's by "unknown"
emotion[is.na(emotion)] = "unknown"

# classify polarity
class_pol = classify_polarity(nexus, algorithm="bayes")
# get polarity best fit
polarity = class_pol[,4]



# data frame with results
sent_df = data.frame(text=nexus, emotion=emotion,
                     polarity=polarity, stringsAsFactors=FALSE)

# sort data frame
sent_df = within(sent_df,
                 emotion <- factor(emotion, levels=names(sort(table(emotion), decreasing=TRUE))))



# plot distribution of emotions
ggplot(sent_df, aes(x=emotion)) +
  geom_bar(aes(y=..count.., fill=emotion)) +
  scale_fill_brewer(palette="Dark2") +
  labs(x="emotion categories", y="number of tweets") +
  ggtitle("Google Neus 6 Tweets \n(classification by emotion)"
  )



# plot distribution of polarity
ggplot(sent_df, aes(x=polarity)) +
  geom_bar(aes(y=..count.., fill=polarity)) +
  scale_fill_brewer(palette="RdGy") +
  labs(x="polarity categories", y="number of tweets") +
  ggtitle("Sentiment Analysis of Tweets about WebSummit\n(Dublin WebSummit)")





# separating text by emotion
emos = levels(factor(sent_df$emotion))
nemo = length(emos)
emo.docs = rep("", nemo)
for (i in 1:nemo)
{
  tmp = nexus[emotion == emos[i]]
  emo.docs[i] = paste(tmp, collapse=" ")
}

# remove stopwords
emo.docs = removeWords(emo.docs, stopwords("english"))
# create corpus
corpus = Corpus(VectorSource(emo.docs))
tdm = TermDocumentMatrix(corpus)
tdm = as.matrix(tdm)
colnames(tdm) = emos

# comparison word cloud
comparison.cloud(tdm, colors = brewer.pal(nemo, "Dark2"),
                 scale = c(3,.5), random.order = FALSE, title.size = 1.5)


#######################################retweets###########################################
#http://stackoverflow.com/questions/13649019/with-r-split-time-series-data-into-time-intervals-say-an-hour-and-then-plot-t
#http://stackoverflow.com/questions/10317470/simple-analog-for-plotting-a-line-from-a-table-object-in-ggplot2
#find number of retweets
library(ggplot2)

rdmTweets <- searchTwitter('#websummit', n=500)
#Create a dataframe based around the results
df <- do.call("rbind", lapply(rdmTweets, as.data.frame))
#Here are the columns
names(df)
#And some example content
head(df,3)


counts=table(df$retweetCount)
barplot(counts)
dev.off()
#find retweets maximum than 30
retweetSubset =subset(df,retweetCount > 50)
qplot(screenName,  data=retweetSubset, geom="bar",weight=retweetCount,fill=screenName)

#time table among each hour
MyDatesTable <- table(cut(df$created, breaks="10 mins"))
subset(df,cut(df$created, breaks="10 mins"))


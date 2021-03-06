
path = setwd('../')
print(path)
source(knitr::purl(paste0(getwd(), '/dari_2.Rmd'), output = tempfile()))
#source for how to source an RMD file: https://stackoverflow.com/questions/10966109/how-to-source-r-markdown-file-like-sourcemyfile-r
setwd(path)

#### loading Data

library(ggplot2)
#settings used in the sumilation
#sart dom: 0%
#dom live: 50%
#rec live: 75% 
#mutation:  3%
PopPath = 'Populations/'
Pop <- read.csv(PopPath %.% 'Population25.csv')[-4] #removing predator column since it is not used
attach(Pop)
Pop$Tot = Rec+Dom+Het

GeneA <- 2*Dom+Het
GeneB <- 2*Rec+Het

detach(Pop)
dtable(Pop)

#### barplot
attach(Pop,warn.conflicts = FALSE)
M = nrow(Pop)
N = 1:M

barplot(Tot[N]-Rec[N]) #total not Rec

barplot(Rec[N]) #total Rec

barplot((Tot[N]-Rec[N])/Tot[N]) #percent not Rec

barplot(Rec[N]/Tot[N]) #Percent rec

Pop$perc <- GeneB/(2*Tot) #percentage rec genes (gene B)
barplot(Pop$perc)
#length(GeneB);length(Tot)
detach(Pop)

#### logistic regreassion
library(stats4)
X <- N
#p.rec <- Pop$Rec/Pop$Tot # %recessive
Y = Pop$perc

results<-MLE(0,0)
barplot(rbind(Y,Logit.curve(N,results@coef)),beside = TRUE,xlab = 'Generation',ylab = 'Percentage Recessive', col = c('black','blue'))
print.('Coefficients: ', results@coef)
print.('Minus Log Likelihood:', results@minuslogl(results@coef[1],results@coef[2]))


#### X^2 test
scale <- max(Pop$Tot) #scale by number of data points
X_2 <- chisq.stat(Y*scale,Logit.curve(N,results@coef)*scale); print.('X^2  = '%+%X_2%+% '.')
pchisq(X_2,29,lower.tail = FALSE)
print('When we scale by multiplying by the number of points, even though we would expect population growth to be logistic, in this case, seeing as the the P-value was only .1, it does not appear to be a good model. ')



scale2 <- max(Pop$Tot)/sum(Y) #scale by making the area under the curve equal to the total number of samples
X_2 <- chisq.stat(Y*scale2,Logit.curve(N,results@coef)*scale2); print.('X^2 = '%+%X_2%+% '.')
pchisq(X_2,29,lower.tail = FALSE)
print.('When we scale so that the total value is the number of points (which should be more accurate), we instead get a P-value of 1 suggesting that this is a VERY good model. This goes to show how sensitive $\\chi^2$ tests are since we only scales by a fact of $\\frac{1}{'%+%round(sum(Y),1)%+%'}$.')


#### Modeling with Arctangent
YY <- Y - ((min(Y)+max(Y))/2)
Y0 <- which.min(abs(YY)) #where the 0s of this YY is. not quite the correct 0, so the fit won't be perfect
X_ <- X - Y0

plot(X_,Y,xlim=c(-15,15))


Y.norm <- function(y) {
  y1 <- y - ((min(y)+max(y))/2)
  y_ <- y1 * atan(max(X_)) / max(y1)
  eval.parent(substitute(y.max <- max(y1)))
  return(y_)
}

Y.denorm <- function(y_) {
  y1 <- y_ / atan(max(X_)) * y.max
  y <- y1 + ((min(Y)+max(Y))/2)
  return(y)
}


Y_ <- Y.norm(Y)


plot(X_,Y_,xlim=c(-15,15))

#take tanget
Y2 <- tan(Y_) 

Coeff <- rev(P.m(X_,y=Y,reg=T,degree = 1));print.(c('a = ','b = ') %.% Coeff) #do linear regression by using projection matrix
fLine <- function(x) {
  Coeff[1]+Coeff[2]*x
}
# plot(X_,Y2,xlim=c(-15,15))
# curve(fLine(x),add = TRUE,col='blue')

expect  <- fLine(X_)
observe <- Y2

vals <- expect %+% observe
val.list <- as.list(as.data.frame(t(vals)))

data_frame <- data.frame(x=N-Y0,val=observe,mins=unlist(lapply(val.list, min)),maxs=unlist(lapply(val.list, max)))

ggplot(data_frame, aes(x)) + 
  stat_function(fun=fLine,colour = 'blue') +
  geom_point( x=N-Y0, y=observe)+
  geom_errorbar(aes(ymin=mins, ymax=maxs), width=.2,
                position=position_dodge(0.05), colour = 'purple') +
  labs(x = 'Domminant', y = 'Recessive %', title = 'Rec ~ Dom')



#undo tanget


y.detan <- function(x) {
  Y.denorm(atan(fLine(x)))
}


# plot(X_,Y,xlim=c(-15,15))
# curve(Y.denorm(atan(fLine(x))),add = TRUE,col='blue')

expect  <- y.detan(X_)
observe <- Y

vals <- expect %+% observe
val.list <- as.list(as.data.frame(t(vals)))

data_frame <- data.frame(x=X_,val=observe,mins=unlist(lapply(val.list, min)),maxs=unlist(lapply(val.list, max)))

ggplot(data_frame, aes(x)) + 
  stat_function(fun=y.detan,colour = 'blue') +
  geom_point( x=X_, y=observe)+
  geom_errorbar(aes(ymin=mins, ymax=maxs), width=.2,
                position=position_dodge(0.05), colour = 'purple') +
  labs(x = 'Domminant', y = 'Recessive %', title = 'Rec ~ Dom')

#multiply by number of data points for X^2 test
expect  %*=% scale
observe %*=% scale

X_2 <- chisq.stat(observe,expect); print.('X^2 = '%+%X_2%+% '.')
pchisq(X_2,29,lower.tail = FALSE); print.('This value is pretty high. ~0.8. That shows that this is a pretty good fit (which can easily be seen). Overall it is quite interesting that an arctanget curve was the best fit.')

#set area under curve to number of data points
expect  %/=% sum(Y)
observe %/=% sum(Y)

X_2 <- chisq.stat(observe,expect); print.('X^2 = '%+%X_2%+% '.')
pchisq(X_2,29,lower.tail = FALSE); print.('This gives a value of 1 which demonstrates a near perfect fit, but since we can see that the version which has larger values (and thus has larger absolute error) is better than the logistic fit, and so is still a better fit.')

#### population change matrix
PopChange <- matrix(nrow = M,ncol = ncol(Pop)); colnames(PopChange) <- colnames(Pop) %.% '.inc' #initialize population change matrix
for (i in 2:M) {
  PopChange[i,] <- as.matrix(Pop)[i,]-as.matrix(Pop)[i-1,] #make each row the change since the previous generation
}
PopChange <- as.data.frame(PopChange) #convert population change matrix to a data-frame

# Make boolean columns for if the variable increased
for (Col in colnames(Pop)) {
  ColNum <- Col %.% '.inc'
  ColBool <- Col %.% '.bool'
  PopChange[ColBool] <- PopChange[ColNum] > 0 # if the variable increased since the last generation
}


hist(PopChange$Tot.inc,breaks = 15,xlab = 'Overall Population Change',main = 'Histogram of Population Change')
print.('We see an interesting spike around -8 and another around 5, but a gap near 8')
dtable(PopChange)

#### Permutation and contingency table
attach(PopChange,warn.conflicts = FALSE)
table(Rec.bool,Het.bool); print.('This seems to show that when Heterozygous or Recessive increase, the other is likely to do so as well.\n','We can test this with a permutation test')

Pval<-permutation.test(Rec.bool[-1]%+%Het.bool[-1],N=10000);
print.( 'we get a P-value of ~' %+% Pval %+% ' (just under 0.05 when done with n = 1,000,000) which shows that this result is statistically significant in that there does appear to be a positive correlation.' )
detach(PopChange)

#### correlation and co-varience
plot(Pop$Dom,Pop$Rec)

print.('We should expect that the domminant and recissive should be negativly coralated because as the number of recissive cells increases the number of domminant cells should be decreasing, and that they should have a high co-varience because they have a large spread.')

Corr <- cor(Pop$Dom,Pop$Rec);print.('We have a correlation of ' %+% Corr %+% '. which is negative as we would expect as stated above.')


covar <- var(Pop$Dom,Pop$Rec);print.('We have a covarience of ' %+% covar %+% '. which is large and negative as we would expect as stated above.')

#### check if dom\~rec fits to �F distribution
X2 <- rep(Pop$Dom,Pop$Rec)

E.X <- mean(X2) #expectation
#E.X <- sum(Pop$Dom*Pop$Rec)/sum(Pop$Rec) #this one works fine, but the above is the same format is was used for variance.

V.X <- sum((X2-E.X)^2/length(X2)) #Variance
#V.X <- Var(Pop$Dom/Pop$Rec)


rate  <- (V.X/E.X)^(-1) 
shape <- (E.X*rate)

#�F
�F <- function(x) {
  return(dgamma(x,shape = shape,rate = rate))
}


�F.curve <- curve(�F(x))
#�F.area  <-integrate(�F,min(Pop$Dom),max(Pop$Dom))
�F.curve.norm   <- �F.curve
�F.curve.norm$x <- �F.curve$x[-1] / max(�F.curve$x[-1]) * max(Pop$Dom)
�F.curve.norm$y <- �F.curve$y[-1] / max(�F.curve$y[-1]) * max(Pop$Rec)# /�F.area$value * sum(Pop$Dom)


plot(Pop$Dom,Pop$Rec)
points(�F.curve.norm$x,�F.curve.norm$y,type='l',col='blue') #pretty good expect in the second fifth


#### % Change with X^2 fit
pChange <- PopChange$perc.inc[-1]
len <- length(pChange)
plot(pChange)

pChange.sum <- sum(pChange)
pChange.norm <- pChange/pChange.sum #normalized data
pChange.df <- sum(pChange.norm*1:len);print.(pChange.df) #calculates the mean, which is then used as the degrees of freedom


dchisq.df <- function(x) {
  dchisq(x,pChange.df)
}
scale <- integrate(dchisq.df,1,len)$value #area under �q2, used to scale the 

x2 <- function(x) {
  ans <- dchisq(x,pChange.df) #X^2 fitted to the correct degrees of freedom
  ans %/=% scale              #divide by area under curve to normalize
  ans %*=% pChange.sum        #multiply by the area it should have
  return(ans)
}


# plot(pChange)
# curve(x2(x),add = T,col='blue') #plots the scaled and fitted �q2

Expect  <- x2(1:len)
Observe <- pChange

vals <- Expect %+% Observe
val.list <- as.list(as.data.frame(t(vals)))

data_frame <- data.frame(x=1:len,val=Observe,mins=unlist(lapply(val.list, min)),maxs=unlist(lapply(val.list, max)))

ggplot(data_frame, aes(x)) + 
  stat_function(fun=x2,colour = 'blue') + #source for plotting functions: https://stackoverflow.com/questions/5177846/plot-a-function-with-ggplot-equivalent-of-curve
  geom_point( x=1:len, y=pChange)+
  geom_errorbar(aes(ymin=mins, ymax=maxs), width=.2,
                position=position_dodge(0.05), colour = 'purple') +#source for plotting error bars: http://www.sthda.com/english/wiki/ggplot2-error-bars-quick-start-guide-r-software-and-data-visualization
  labs(x = 'Generation', y = 'Change rec. %', title = '% Change with X^2 fit')



t.test(Observe,Expect); print.('We get a P-value of', t.test(Observe,Expect)$p.value ,'which shows that these likely come from the same distribution.')

#Do with X^2 (this means that the data needs to be scaled)
Expect  %*=% (len / sum(pChange))
Observe  %*=% (len / sum(pChange))

X_2 <- chisq.stat(Observe,Expect); print.('X^2 = '%+%X_2%+% '.')
pchisq(X_2,29,lower.tail = FALSE); print.('\n However, when we do a X^2 test, we end up with a very low P-value, which would suggest that this is a bad fit.','\n\n','It should also be noted that for both of these tests the null hypothesis is that the two data points come from the same distribution, meaning that a high P-value means that they are related. (unlike a permutation test which has independance as the null and thus the reverse meaning of P-values)')


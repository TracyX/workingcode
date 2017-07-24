library(data.table)
system.time(data<- fread("/home/recsys/zhongziyan/tag_model/tag_49_withskip.txt",sep="\t")) 

data <- setNames(data, c("hour","pin","tag","cnt_clk","cnt_ord",
"f1","f2","f3","f4","f5","f6","f7","f8","f9",
"f10","f11","f12","f13","f14","f15","f16","f17","f18","f19",
"f20","f21","f22","f23","f24","f25","f26","f27","f28","f29",
"f30","f31","f32","f33","f34","f35","f36","f37","f38","f39",
"f40","f41","f42","f43","f44","f45","f46","f47","f48","skip_real"))


data$prc_grade_diff_bin=0
data$prc_grade_diff_bin[data$prc_grade_diff!=0]=1



random <- runif(nrow(data), 0, 1)

data1 <- data[order( random), ]


trainset <- data1[1:ceiling(nrow(data1)/2), ]
testset<- data1[(ceiling(nrow(data1)/2) + 1) : nrow(data1), ]


library(gbm)

model <- gbm(cvr~., data=trainset,shrinkage=0.05,
             cv.folds=4,n.trees=300,verbose=F)  
best.iter <- gbm.perf(model,method='cv')
summary(model,best.iter)

xx_train <- trainset[, c(1,3,6:53),with=F]
 
yy <- trainset[,skip_real]
xx_test <- testset[, c(1,3,6:53),with=F]

yytest <- testset[,skip_real]

f <- glm(yy ~ ., data = xx_train, family = 'binomial')
summary(f)
glm_pre=predict(f,  xx_test)
glm_pre=as.numeric(glm_pre)
aa=cbind(glm_pre,yytest)
aa1=aa[yytest>0,]
seaa=mean(abs(aa1[,1]-aa1[,2]))
se=mean(abs(glm_pre-yytest))

library(glmnet)
glm.net.sol2 <- cv.glmnet(xx_train, yy, alpha = 0.5)
coef2<- coef(glm.net.sol2, s=glm.net.sol2$lambda.min)
system.time(glm.net.sol3<- cv.glmnet(as.matrix(xx_train), yy, alpha = 0.1,intercept=FALSE,type.measure='auc',family="binomial"))

coef3<- coef(glm.net.sol3, s=glm.net.sol3$lambda.min)
glm.net.sol4<- cv.glmnet(xx_train, yy, alpha = 0.01,intercept=FALSE,lower.limits=0)
coef4<- coef(glm.net.sol4, s=glm.net.sol4$lambda.min)
system.time(glm.net.sol5<- cv.glmnet(xx_train[,c(-19,-20)], yy, alpha = 0.01,intercept=FALSE))
coef5<- coef(glm.net.sol5, s=glm.net.sol5$lambda.min)
print(glm.net.sol3)
glm.net.sol1<- cv.glmnet(xx_train, yy, alpha = 0.5,lower.limits=0)
plot(glm.net.sol2 ,xvar="lambda",label=TRUE)

pred <- predict(glm.net.sol3, newx=xx_test, s=glm.net.sol3$lambda.min)
pred=as.numeric(pred)
aa=cbind(pred,yytest)
aa1=aa[yytest>0,]
seaa=mean(abs(aa1[,1]-aa1[,2]))
se=mean(abs(pred-yytest))

pred1 <- predict(glm.net.sol2, newx=xx_test, s=glm.net.sol2$lambda.min)
pred1=as.numeric(pred1)
aa=cbind(pred1,yytest)
aa1=aa[yytest>0,]
seaa1=mean(abs(aa1[,1]-aa1[,2]))
se1=mean(abs(pred1-yytest))

pred2 <- predict(glm.net.sol4, newx=xx_test, s=glm.net.sol4$lambda.min)
pred2=as.numeric(pred2)
aa=cbind(pred2,yytest)
aa1=aa[yytest>0,]
seaa2=mean(abs(aa1[,1]-aa1[,2]))
se2=mean(abs(pred2-yytest))
 
 

pred3 <- predict(glm.net.sol5, newx=xx_test[,c(-26,-27,-35)], s=glm.net.sol5$lambda.min)
pred3=as.numeric(pred3)
aa=cbind(pred3,yytest)
aa1=aa[yytest>0,]
seaa3=mean(abs(aa1[,1]-aa1[,2]))
se3=mean(abs(pred3-yytest))


trainset <- data1[1:ceiling(nrow(data1)/8), ]
testset<- data1[(ceiling(nrow(data1)/8) + 1) : nrow(data1), ]






Coefficients: (2 not defined because of singularities)
              Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.715e+02  7.535e+00 -22.766  < 2e-16 ***
hour         8.645e-03  4.024e-04  21.480  < 2e-16 ***

f2          -1.008e-01  1.220e-02  -8.265  < 2e-16 ***
  
f6          -3.675e-01  6.530e-03 -56.285  < 2e-16 ***

f9           2.485e-01  2.323e-03 106.992  < 2e-16 ***
f13          5.986e+01  2.574e+00  23.257  < 2e-16 ***
   
f21         -5.099e+02  2.195e+01 -23.228  < 2e-16 ***
f23         -2.855e+02  4.108e+01  -6.951 3.64e-12 ***
f47                 NA         NA      NA       NA    
f48                 NA         NA      NA       NA    



platform = "linux"
rfhome ="/home/recsys/xiongxi/rulefit" 
source("/home/recsys/xiongxi/rulefit/rulefit.r")
install.packages("akima", lib=rfhome)
library(akima, lib.loc=rfhome) 
yy[yy<1]=-1
rfmod = rulefit (xx_train, yy,   cat.vars=c(1,2), not.used=c(49),rfmode="class", sparse=0.5, test.reps=0, test.fract=0.2, mod.sel=1,  model.type="both",  tree.size=4, max.rules=200 , max.trms=50 , costs=c(2,1),  quiet=F) 
runstats(rfmod)
vi = varimp (impord =TRUE,x=xx_train)
rules( beg=1, end=10, x=xx_train )



D:/RecModels/rec130000/globle mercury/rulefit



rules=function(beg=1,end=beg+9,x=NULL,wt=rep(1,n)) {
   beg <- parchk("beg",beg,1,1000000,1)
   end <- parchk("end",end,beg,1000000,beg+9)
   zz=file(paste(rfhome,'/intparms',sep=''),'rb')
   ip=readBin(zz,integer(),size=4,n=4); close(zz); ni=ip[4]
   if(!missing(x)) { mode=1
      if(is.data.frame(x)) { p=length(x); n=length(x[[1]])
         xx=matrix(nrow=n,ncol=p); for (j in 1:p) { xx[,j]=x[[j]]}
      }
      else if(is.matrix(x)) { n <- nrow(x); p <- ncol(x); xx=x;}
      else if(is.vector(x)) { p=length(x); n=1; xx=x}
      else { stop(' x must be a data frame, matrix, or vecing message:
running command 'cmd /c rf_go.exe' had status 41 tor.')}
      if(p!=ni)
         stop(paste(' number of variables =',as.character(p),
            'is different from training data =',as.character(ni)))
      if(any(is.na(xx))) {
         zz=file(paste(rfhome,'/realparms',sep=''),'rb')
         xmiss=readBin(zz,numeric(),size=8,n=1); close(zz)
         xx[is.na(xx)] <- xmiss;
      }
      zz=file(paste(rfhome,'/varimp.x',sep=''),'wb')
      writeBin(as.numeric(c(n,as.vector(xx))),zz,size=8); close(zz)
      putw(wt,xx,n,p,'varimp.w')
   }
   else { mode=0}
   zz=file(paste(rfhome,'/intrules',sep=''),'wb')
   writeBin(as.integer(c(mode,beg,end)),zz,size=4); close(zz)
   wd=getwd(); setwd(rfhome)
   status=rfexe('rules')
}
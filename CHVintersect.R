########################################################################################################################
#                                                                                                                      #
# AUTHOR: Sebastien Villeger                                                                                           #
# modified to accept paths to files                                                                                    #
#                                                                                                                      #
# function to compute convex hull (vertices + volume) of two set of points                                             #
#                             and their intersection in a D-dimensions space (D>=2)                                    #
#  -> requires packages "rcdd' and 'geometry'                                                                          #
#                                                                                                                      #
# inputs:                                                                                                              #
#         - set1: matrix(N1*D) with coordinates of the first set of points in D-dimensions                             #
#         - set2: matrix(N2*D) with coordinates of the second set of points in D-dimensions                            #
#                  ->  N1 and N2 must be strictly higher than D                                                        #
#         - NA are not allowed                                                                                         #
#                                                                                                                      #
# outputs:                                                                                                             #
#          - $vert_set1: matrix with coordinates of the vertices delimiting the convex hull of set1                    #
#          - $vert_set2: matrix with coordinates of the vertices delimiting the convex hull of set2                    #
#          - $vert_intersect: matrix with coordinates of the vertices delimiting the intersection between the two sets #
#          - $vol: vector (length 3) with convex hull volume of set1, set2 and their intersection                      #
########################################################################################################################


CHVintersect<-function(path1, path2) {
    
    
    ################################
    # loading required libraries   # 
    library(geometry)              #
    library(rcdd)                  #
    ################################
    
    set1 = as.matrix(read.table(path1))
    set2 = as.matrix(read.table(path2))
    
    ###########################
    # checking inputs         #
    ###########################
    # number of dimensions
    if(ncol(set1)!=ncol(set2)) stop("error : different number of dimensions in the two set of points") 
    
    # number of points
    if (nrow(set1)<=ncol(set1))  stop(paste("error : 'set1' must contain at least ",ncol(set1)+1, " points",sep=""))
    if (nrow(set2)<=ncol(set2))  stop(paste("error : 'set2' must contain at least ",ncol(set2)+1, " points",sep=""))
    
    # checking absence of NA
    if (length(which(is.na(set1)==T))!=0) stop(paste("error : NA are not allowed in coordinates of 'set1'",sep=""))
    if (length(which(is.na(set2)==T))!=0) stop(paste("error : NA are not allowed in coordinates of 'set2'",sep=""))
    
    ##############################################################################
    # tranforming coordinates in true rational number written as character string
    set1rep <- d2q(cbind(0, cbind(1, set1)))
    set2rep <- d2q(cbind(0, cbind(1, set2)))
    
    
    # reduce set of points to vertices only using redundant function
    polytope1 <- redundant(set1rep, representation = "V")$output
    polytope2 <- redundant(set2rep, representation = "V")$output
    
    
    # changing polytope representation: vertices to inequality constraints
    H_chset1 <- scdd(polytope1, representation = "V")$output
    H_chset2 <- scdd(polytope2, representation = "V")$output
    
    
    # intersection between the two polytopes
    H_inter <- rbind(H_chset1, H_chset2)
    V_inter <- scdd(H_inter, representation = "H")$output
    
    
    # extracting coordinates of vertices
    vert_set1 <- q2d(polytope1[ , - c(1, 2)])
    vert_set2 <- q2d(polytope2[ , - c(1, 2)])
    vert_inter <- q2d(V_inter[ , - c(1, 2)])
    
    
    # computing convex hull volume of the two polytopes and of their intersection if it exists 
    # (no intersection if one vertex in common)
    vol<-rep(0,3) ; names(vol)<-c("vol_set1","vol_set2","vol_inter")
    vol["vol_set1"]<-convhulln(vert_set1,"FA")$vol
    vol["vol_set2"]<-convhulln(vert_set2,"FA")$vol
    if (is.matrix(vert_inter)==T) # vector if one vertex in common
        if( nrow(vert_inter)>ncol(vert_inter) ) vol["vol_inter"]<-convhulln(vert_inter,"FA")$vol
    
    
    ################################################################################
    # results
    
    res<-list(vert_set1=vert_set1, vert_set2=vert_set2, vert_inter=vert_inter, vol=vol)
    
    return(res)    
    
} # end of function CHVintersect


#################################################################
# exemple

showexample<-F

if (showexample==T) {
    
    # trivial example in 2D with 4 communities
    A<-cbind( c(6,10,12,10,6), c(6,6,8,10,9) ) ; B<-cbind( c(4,8,9,9,5,4), c(4,4,6,7,7,5) )
    C<-cbind( c(3,5,7,7,5,3), c(6,4,5,8,10,9) ) ; D<-cbind( c(10,12,12,10), c(3,3,8,8) )
    
    # graphic
    col<-c("#FF570A", "#4B8AEF", "#11A123", "#ADAEAE")
    plot(rbind(A,B,C,D),type="n", xlab="Trait 1", ylab="Trait 2",xlim=c(2.5,12.5),ylim=c(2.5,10.5) )
    abline(v=1:12, lty=2, col="grey") ; abline(h=1:12, lty=2, col="grey") # grid to "see" surfaces
    points(A,pch=21,col=col[1],bg=col[1],cex=1.5) ; points(B,pch=21,col=col[2],bg=col[2],cex=1)
    points(C,pch=21,col=col[3],bg=col[3],cex=1) ; points(D,pch=21,col=col[4],bg=col[4],cex=1)
    polygon(A,border=col[1],col=paste(col[1],80,sep=""), lwd=2 )
    polygon(B,border=col[2],col=paste(col[2],80,sep=""), lwd=2 ) 
    polygon(C,border=col[3],col=paste(col[3],80,sep=""), lwd=2 )
    polygon(D,border=col[4],col=paste(col[4],80,sep=""), lwd=2 )
    text(9,8,"A",col=col[1],cex=3) ; text(7.5,5.5,"B",col=col[2],cex=3)
    text(4.5,8,"C",col=col[3],cex=3) ; text(11,5.5,"D",col=col[4],cex=3)
    
    
    # intersection between A and B
    AB<-CHVintersect(A,B) 
    print("#########  AB") ; print(AB)
    
    # intersection between A and C
    AC<-CHVintersect(A,C) 
    print("#########  AC") ; print(AC)
    
    # intersection between B and C
    BC<-CHVintersect(B,C) 
    print("#########BC")  ; print(BC)
    
    # intersection between C and D ; none !
    CD<-CHVintersect(C,D) 
    print("######### CD")  ; print(CD)
    
    
} # end of showexample  
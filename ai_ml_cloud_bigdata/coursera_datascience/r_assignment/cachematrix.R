## Matrix inversion is a costly computation
## Below pair of functions are to allow user to cache Matrix Inverse when calculated for the first time
## and retrieve that cached Matrix Inverse instead of re-computing

## makeCacheMatrix: This function creates a special "matrix" object that can cache its inverse.
makeCacheMatrix <- function(x = matrix()) {
  cachedInverseMatrix <- NULL
  
  list(
    setMatrix = function(inputMatrix) {
      x <<- inputMatrix
      cachedInverseMatrix <<- NULL
    },
    
    getMatrix = function() {
      x
    },
    
    setMatrixInverse = function(externallyCalculatedInverse) {
      cachedInverseMatrix <<- externallyCalculatedInverse
    },
    
    getMatrixInverse = function() {
      cachedInverseMatrix
    }
  )
}

## cacheSolve: This function computes the inverse of the special "matrix"
## returned by makeCacheMatrix above. If the inverse has 
## already been calculated (and the matrix has not changed), then 
## the cachesolve should retrieve the inverse from the cache.
cacheSolve <- function(x, ...) {
    ## Return a matrix that is the inverse of 'x'
	sourceMatrx <- NULL
	inverseMatrix <- x$getMatrixInverse()
  
	if (is.null(inverseMatrix)) {
		srcMatrx <- x$getMatrix()
		inverseMatrix <- solve(srcMatrx)
		x$setMatrixInverse(inverseMatrix)
	}
	
	inverseMatrix
}

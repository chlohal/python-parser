#=====================================
# Import statements
#=====================================

import a, b
import b.c as d
import a.b.c

#=====================================
# Import-from statements
#=====================================

from a import b
from a import *
from a import (b, c)
from a.b import c
from . import b
from .. import b
from .a import b
from ..a import b

#=====================================
# Function calls
#=====================================

a(b)
a('d')

#=====================================
# Future import statements
#=====================================

from __future__ import print_statement
from __future__ import python4
from __future__ import (absolute_import, division, print_function, unicode_literals)

#=====================================
# Print statements
#=====================================

print a
print b, c
print 0 or 1, 1 or 0,
print 0 or 1

#=====================================
# Print statements with redirection
#=====================================

print >> a
print >> a, "b", "c"

#=====================================
# Assert statements
#=====================================

assert a
assert b, c

#=====================================
# Expression statements
#=====================================

a
b + c
1, 2, 3
1, 2, 3,

#=====================================
# Delete statements
#=====================================

del a[1], b[2]

#=====================================
# Control-flow statements
#=====================================

while true:
  pass
  break
  continue

#=====================================
# Return statements
#=====================================

return
return a + b, c
return not b

#=====================================
# If statements
#=====================================

if a:
  b
  c

#=====================================
# If else statements
#=====================================

if a:
  b
elif c:
  d
else:
  f

if a:
  b
else:
  f

if a: b

if a: b; c

#=====================================
# Nested if statements
#=====================================

if a:
  if b:
    c
  else:
    if e:
      f
g

#=====================================
# While statements
#=====================================

while a:
  b

while c:
  d
else:
  e
  f

#=====================================
# For statements
#=====================================

for line, i in lines:
  print line
  for character, j in line:
    print character
else:
  print x

for x, in [(1,), (2,), (3,)]:
  x

#=====================================
# Try statements
#=====================================

try:
  a
except b:
  c
except d as e:
  f
except g, h:
  i
except:
  j

try:
  a
except b:
  c
  d
else:
  e
finally:
  f

#=====================================
# With statements
#=====================================

with a as b:
  c

with (open('d') as d, open('e') as e):
  f

with g:
  h


#=====================================
# Async Function definitions
#=====================================

async def a():
  b

async def c(d):
  e

async def g(g, h):
  i

async def c(a: str):
  a

async def c(a: b.c):
  a

async def d(a: Sequence[T]) -> T:
  a

async def i(a, b:=c, *c, **d):
  a

async def d(a: str) -> None:
  return None

async def d(a:str="default", b=c) -> None:
  return None

#=====================================
# Function definitions
#=====================================

def e((a,b)):
  return (a,b)

def e(*list: str):
  pass

def e(**list: str):
  pass

def f():
  nonlocal a

def g(h, i, *, j, k=100, **kwarg):
  return h,i,j,k,kwarg

def h(*a):
  i((*a))
  j(((*a)))

#==================================
# Empty blocks
#==================================

# These are not actually valid python; blocks
# must contain at least one statement. But we
# allow them because error recovery for empty
# blocks doesn't work very well otherwise.

# NOTE: NO WE DO NOT SUPPORT THESE!
# THIS IS A NAIVE PARSER! IT DOES NOT SUPPORT ERROR RECOVERY OF ANY TYPE
# NO THANK YOU
# BYE
# HAVE A GOOD DAY THAT WAS HARSH SORRY IT'S LIKE 1 AM

def a(b, c):
  pass

if d:
  print e
  while f():
    pass



#====================================================
# Class definitions
#====================================================

class A:
  def b(self):
    return c
class B():
  pass
class B(method1):
  def method1(self):
    return

#====================================================
# Class definitions with superclasses
#====================================================

class A(B, C):
  def d():
    e

#====================================================
# Decorated definitions
#====================================================

@a.b
def c():
  pass

#====================================================
# Raise statements
#====================================================

raise
raise RuntimeError('NO')
raise RunTimeError('NO') from e

#====================================================
# Comments
#====================================================

print a
# hi
print b # bye
print c

#====================================================
# Comments at different indentation levels
#====================================================

#====================================================
# Comments after dedents
#====================================================

if a:
  b

# one
c

#====================================================
# Comments at the ends of indented blocks
#====================================================


#====================================================
# Newline tokens followed by comments
#====================================================

#====================================================
# Global statements
#====================================================

global a
global a, b

#====================================================
# Exec statements
#====================================================

exec '1+1'
exec 'x+=1' in None
exec 'x+=1' in a, b

#==================================================
# Extra newlines
#==================================================
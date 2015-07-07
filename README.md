# JDBC - Julia interface to Java JDBC database drivers

[![Build Status](https://travis-ci.org/aviks/JDBC.jl.svg?branch=master)](https://travis-ci.org/aviks/JDBC.jl)


##Example

```julia
               _
   _       _ _(_)_     |  A fresh approach to technical computing
  (_)     | (_) (_)    |  Documentation: http://docs.julialang.org
   _ _   _| |_  __ _   |  Type "help()" for help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 0.3.9-pre+27 (2015-05-20 15:14 UTC)
 _/ |\__'_|_|_|\__'_|  |  Commit 8418a3a* (48 days old release-0.3)
|__/                   |  x86_64-apple-darwin13.4.0

julia> using JavaCall
Loaded /Library/Java/JavaVirtualMachines/jdk1.7.0_76.jdk/Contents/Home/jre/lib/server/libjvm.dylib

julia> using JDBC

julia> JavaCall.addClassPath(joinpath(Pkg.dir("JDBC"), "test", "derby.jar"))
1-element Array{String,1}:
 "/Users/aviks/.julia/v0.3/JDBC/test/derby.jar"

julia> JavaCall.init()

julia> conn = DriverManager.getConnection("jdbc:derby:test/juliatest")

signal (11): Segmentation fault: 11
unknown function (ip: 333085400)
JavaObject{symbol("java.sql.Connection")}(Ptr{Void} @0x00007fc4c9c62750)

julia> stmt = createStatement(conn)
JavaObject{symbol("java.sql.Statement")}(Ptr{Void} @0x00007fc4c9c62760)

julia> rs = executeQuery(stmt, "select * from firsttable")
JavaObject{symbol("java.sql.ResultSet")}(Ptr{Void} @0x00007fc4c9c62778)

julia> for r in rs
         println(getInt(r, 1)," ", getString(r,"NAME"))
       end
10 TEN
20 TWENTY
30 THIRTY
```

# JDBC - Julia interface to Java JDBC database drivers

[![Build Status](https://travis-ci.org/aviks/JDBC.jl.svg?branch=master)](https://travis-ci.org/aviks/JDBC.jl)


##Example Usage

```julia
julia> using JavaCall
Loaded /Library/Java/JavaVirtualMachines/jdk1.7.0_76.jdk/Contents/Home/jre/lib/server/libjvm.dylib

julia> using JDBC

julia> JavaCall.addClassPath(joinpath(Pkg.dir("JDBC"), "test", "derby.jar"))

julia> JavaCall.init()

julia> conn = DriverManager.getConnection("jdbc:derby:test/juliatest")
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

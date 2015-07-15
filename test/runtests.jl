#This file is part of JDBC.jl. License is MIT.
using JavaCall
using JDBC
using Base.Test
using DataFrames
using Dates

JavaCall.addClassPath(joinpath(Pkg.dir("JDBC"), "test", "derby.jar"))
JavaCall.init()
conn = DriverManager.getConnection("jdbc:derby:jar:(toursdb.jar)toursdb")
stmt = createStatement(conn)
rs = executeQuery(stmt, "select * from airlines")

airlines=readtable(rs)
@assert size(airlines) == (2,9)
@assert airlines[1, :BASIC_RATE] == 0.18
@assert airlines[2, :BASIC_RATE] == 0.19
@assert airlines[1, :ECONOMY_SEATS] == 20
@assert airlines[1, :AIRLINE] == "AA"

close(rs)

rs = executeQuery(stmt, "select * from flights")
flights=readtable(rs)
size(flights) == (542,10)
@assert flights[1, :FLIGHT_ID]=="AA1111"
@assert flights[1, :FLYING_TIME] == 1.328
@assert flights[1, :DEPART_TIME]==DateTime(1970, 1, 1, 9,0,0)
@assert flights[1, :ARRIVE_TIME]==DateTime(1970, 1, 1, 9, 19,0)
@assert flights[542, :FLYING_TIME] == 0.622
@assert flights[542, :DEPART_TIME]==DateTime(1970, 1, 1, 19,0,0)
@assert flights[542, :ARRIVE_TIME]==DateTime(1970, 1, 1, 19, 37,0)
@assert flights[541, :FLYING_TIME] == 10.926
@assert flights[541, :DEPART_TIME]==DateTime(1970, 1, 1, 5,0,0)
@assert flights[541, :ARRIVE_TIME]==DateTime(1970, 1, 1, 17, 55,0)

close(rs)
close(stmt)

JavaCall.destroy()

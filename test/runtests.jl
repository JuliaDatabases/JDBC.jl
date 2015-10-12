#This file is part of JDBC.jl. License is MIT.
using DataFrames
using JavaCall
using JDBC
using Base.Test

if VERSION < v"0.4-"
    using Dates
else
    using Base.Dates
end
using Compat

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
close(conn)

#Test write

if isdir("tmptest")
    rm("tmptest", recursive=true)
end
@assert !isdir("tmptest")

d=@compat Dict("create"=>"true")
conn = DriverManager.getConnection("jdbc:derby:tmptest", d)

stmt = createStatement(conn)

executeUpdate(stmt, "CREATE TABLE FIRSTTABLE
                   (ID INT PRIMARY KEY,
                   NAME VARCHAR(12))")
ppstmt = prepareStatement(conn, "insert into firsttable values (?, ?)")
setInt(ppstmt, 1,10)
setString(ppstmt, 2,"TEN")
executeUpdate(ppstmt)
setInt(ppstmt, 1,20)
setString(ppstmt, 2,"TWENTY")
executeUpdate(ppstmt)
rs=executeQuery(stmt, "select * from FIRSTTABLE")
ft = readtable(rs)
@assert size(ft) == (2,2)
ft[1, :ID] == 10
ft[1, :NAME] == "TEN"
ft[1, :ID] == 20
ft[1, :NAME] == "TWENTY"

close(rs)
close(stmt)
close(ppstmt)

#Test calling stored procedures
cstmt = JDBC.prepareCall(conn, "CALL SYSCS_UTIL.SYSCS_SET_DATABASE_PROPERTY(?, ?)")
setString(cstmt, 1, "derby.locks.deadlockTimeout")
setString(cstmt, 2, "10")
execute(cstmt) #no exection thrown
close(cstmt)

close(conn)

rm("tmptest", recursive=true)
@assert !isdir("tmptest")

JavaCall.destroy()

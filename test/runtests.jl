#This file is part of JDBC.jl. License is MIT.
using JavaCall
using JDBC
using DataFrames
using DataStreams
using Test
using Dates
import Pkg

derby_driver_path = joinpath(dirname(pathof(JDBC)),"..","test","derby.jar")

JDBC.usedriver(derby_driver_path)

JDBC.init()

conn = DriverManager.getConnection("jdbc:derby:jar:(toursdb.jar)toursdb")
stmt = createStatement(conn)
rs = executeQuery(stmt, "select * from airlines")

@testset "Query1" begin
    airlines = JDBC.load(DataFrame, rs)
    @test size(airlines) == (2,9)
    @test airlines[1, :BASIC_RATE] == 0.18
    @test airlines[2, :BASIC_RATE] == 0.19
    @test airlines[1, :ECONOMY_SEATS] == 20
    @test airlines[1, :AIRLINE] == "AA"
end

close(rs)

# Tests for `getTableMetaData` and `JDBCRowIterator`.`
rs = executeQuery(stmt, "select * from airlines")
iter = JDBCRowIterator(rs)
airlines = collect(iter)

@testset "RowIterator" begin
    @test getTableMetaData(rs) == [("AIRLINE", JDBC.JDBC_COLTYPE_CHAR),
                                   ("AIRLINE_FULL", JDBC.JDBC_COLTYPE_VARCHAR),
                                   ("BASIC_RATE", JDBC.JDBC_COLTYPE_DOUBLE),
                                   ("DISTANCE_DISCOUNT", JDBC.JDBC_COLTYPE_DOUBLE),
                                   ("BUSINESS_LEVEL_FACTOR", JDBC.JDBC_COLTYPE_DOUBLE),
                                   ("FIRSTCLASS_LEVEL_FACTOR", JDBC.JDBC_COLTYPE_DOUBLE),
                                   ("ECONOMY_SEATS", JDBC.JDBC_COLTYPE_INTEGER),
                                   ("BUSINESS_SEATS", JDBC.JDBC_COLTYPE_INTEGER),
                                   ("FIRSTCLASS_SEATS", JDBC.JDBC_COLTYPE_INTEGER)]
    @test size(airlines) == (2,)
    @test length(airlines[1]) == 9
    @test airlines[1][3] == 0.18
    @test airlines[2][3] == 0.19
    @test airlines[1][7] == 20
    @test airlines[1][1] == "AA"
    close(rs)
end

rs = executeQuery(stmt, "select * from flights")
flights = JDBC.load(DataFrame, rs)

# TODO think these datetimes get screwed up because of time zones
# not sure if this is even something that can actually get "fixed"
@testset "Query2" begin
    @test size(flights) == (542,10)
    @test flights[1, :FLIGHT_ID] == "AA1111"
    @test flights[1, :FLYING_TIME] == 1.328
    # @test flights[1, :DEPART_TIME] == DateTime(1970, 1, 1, 9,0,0)
    # @test flights[1, :ARRIVE_TIME] == DateTime(1970, 1, 1, 9, 19,0)
    @test Date(flights[1,:DEPART_TIME]) == Date(1970, 1, 1)
    @test Date(flights[1,:ARRIVE_TIME]) == Date(1970, 1, 1)
    @test flights[542, :FLYING_TIME] == 0.622
    # @test flights[542, :DEPART_TIME] == DateTime(1970, 1, 1, 19,0,0)
    # @test flights[542, :ARRIVE_TIME] == DateTime(1970, 1, 1, 19, 37,0)
    @test Date(flights[542, :DEPART_TIME]) == Date(1970, 1, 1)
    @test Date(flights[542, :ARRIVE_TIME]) == Date(1970, 1, 1)
    @test flights[541, :FLYING_TIME] == 10.926
    # @test flights[541, :DEPART_TIME] == DateTime(1970, 1, 1, 5,0,0)
    # @test flights[541, :ARRIVE_TIME] == DateTime(1970, 1, 1, 17, 55,0)
    @test Date(flights[541, :DEPART_TIME]) == Date(1970, 1, 1)
    @test Date(flights[541, :ARRIVE_TIME]) == Date(1970, 1, 1)
end

close(rs)
close(stmt)
close(conn)

#Test write

if isdir("tmptest")
    rm("tmptest", recursive=true)
end
@assert !isdir("tmptest")

d = Dict("create"=>"true")
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
ft = JDBC.load(DataFrame, rs)

@testset "Query3" begin
    @test size(ft) == (2,2)
    @test ft[1, :ID] == 10
    @test ft[1, :NAME] == "TEN"
    @test ft[2, :ID] == 20
    @test ft[2, :NAME] == "TWENTY"
end

close(rs)
close(stmt)
close(ppstmt)

#Test calling stored procedures
cstmt = JDBC.prepareCall(conn, "CALL SYSCS_UTIL.SYSCS_SET_DATABASE_PROPERTY(?, ?)")
setString(cstmt, 1, "derby.locks.deadlockTimeout")
setString(cstmt, 2, "10")
execute(cstmt) #no exection thrown
close(cstmt)

# test DBAPI functions
dbconn = JDBC.Connection("jdbc:derby:jar:(toursdb.jar)toursdb",
                         connectorpath=derby_driver_path)

csr = cursor(dbconn)
execute!(csr, "select * from airlines")
global airlines = collect(rows(csr))

@testset "Query4" begin
    @test size(airlines) == (2,)
    @test length(airlines[1]) == 9
    @test airlines[1][3] == 0.18
    @test airlines[2][3] == 0.19
    @test airlines[1][7] == 20
    @test airlines[1][1] == "AA"
end

close(csr)

@testset "JuliaInterface" begin
    global airlines = JDBC.load(DataFrame, cursor(dbconn), "select * from airlines")
    @test size(airlines) == (2,9)
    @test airlines[1, 3] == 0.18
    @test airlines[2, 3] == 0.19
    @test airlines[1, 7] == 20
    @test airlines[1, 1] == "AA"
end

close(dbconn)

@info("The following Java exception is expected if test pases:")
@test_throws Exception DriverManager.getConnection("jdbc:derby:;shutdown=true")

rm("tmptest", recursive=true)

JDBC.destroy()

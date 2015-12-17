# JDBC - Julia interface to Java JDBC database drivers

[![Build Status](https://travis-ci.org/JuliaDB/JDBC.jl.svg?branch=master)](https://travis-ci.org/JuliaDB/JDBC.jl)  [![Build status](https://ci.appveyor.com/api/projects/status/3m0pq27s24mkaduq?svg=true)](https://ci.appveyor.com/project/aviks/jdbc-jl)  [![JDBC](http://pkg.julialang.org/badges/JDBC_0.3.svg)](http://pkg.julialang.org/?pkg=JDBC)  [![JDBC](http://pkg.julialang.org/badges/JDBC_0.4.svg)](http://pkg.julialang.org/?pkg=JDBC)  [![JDBC](http://pkg.julialang.org/badges/JDBC_0.5.svg)](http://pkg.julialang.org/?pkg=JDBC)


This package enables the use of Java JDBC drivers to access databases from within Julia. It uses the [JavaCall.jl](https://github.com/aviks/JavaCall.jl) package to call into Java in order to use the JDBC drivers. 

The API provided by this package is very similar to the native JDBC API, with the necessary changes to move from 
an object oriented syntax to a Julia's more *functional* syntax. So while a Java method is transformed to a Julia function
with the same name, the reciever in Java (the object before the dot) becomes the first argument to the Julia function. For
example, `statement.executeQuery(sql_string)` in Java becomes, in Julia: `executeQuery(statement, sql_string)`. 
Therefore, some familiarity with JDBC is useful for working with this package. 

In JDBC, accessing the data frome a SQL call is done by iterating over a `ResultSet` instance. In Julia therefore, the `ResultSet` is a regular Julia iterator, and can be iterated in the usual fashion. 

There is however, an optional `readtable` method that is defined when `DataFrames` is loaded. This converts a JDBC resultset into a Julia DataFrame. 




###Initialisation

To start it up, add the database driver jar file to the classpath, and then initialise the JVM. 

```julia
using JDBC
JavaCall.addClassPath("/home/me/derby/derby.jar")
JDBC.init() # or JavaCall.init()
 ```
###Basic Usage

As described above, using this package is very similar to using a JDBC driver in Java. Write the Julia code in a way that is very similar to how corresponding Java code would look. 

```julia
conn = DriverManager.getConnection("jdbc:derby:test/juliatest")
stmt = createStatement(conn)
rs = executeQuery(stmt, "select * from firsttable")
 for r in rs
      println(getInt(r, 1),  getString(r,"NAME"))
 end
```

To get each row as a julia tuple, iterate over the result set using `JDBCRowIterator`.  Values in the tuple will be of Nullable type if they are declared to be nullable in the database.

```julia
for r in JDBCRowIterator(rs)
    println(r)
end
```

The following accessor functions are defined. Each of these functions take two arguments:  the `Resultset`, and either a field index or a field name. The result of these accessor functions is always a pure Julia object. All conversions from Java types are done before they are returned from these functions. 
```julia
getInt
getFloat
getString 
getShort 
getByte 
getTime 
getTimeStamp 
getDate
getBoolean
getNString
getURL
```
###Updates

While inserts and updates can be done via a fully specified SQL string using the `Statement` instance above, it is much safer to do so via a `PreparedStatement`. A `PreparedStatement` has setter functions defined for different types, corresponding to the getter functions shown above. 

```
ppstmt = prepareStatement(conn, "insert into firsttable values (?, ?)")
setInt(ppstmt, 1,10)
setString(ppstmt, 2,"TEN")
executeUpdate(ppstmt)
```

Similary, a `CallableStatement` can be used to run stored procedures. A `CallableStatement` can have both input and output parameters, and thus has both getter and setter functions defined. 
```julia
cstmt = JDBC.prepareCall(conn, "CALL SYSCS_UTIL.SYSCS_SET_DATABASE_PROPERTY(?, ?)")
setString(cstmt, 1, "derby.locks.deadlockTimeout")
setString(cstmt, 2, "10")
execute(cstmt)
```

Note that as per the JDBC API there are two kinds of execute methods defined on a `Statement` : `executeQuery` returns a ResultSet (usually from a `select`), and `executeUpdate` returns an Integer which denotes the number of rows effected by a query (usually an `update` or `insert` or a DDL). For `PreparedStatements` and `CallableStatements`, an additional function `execute` is defined which returns a boolean which specifies whether a ResultSet has been returned from the query. 

Also note that for a `Statement`, the query itself is specified in the corresponding `execute..` call, while for a `PreparedStatement` and a `CallableStatement`, the query itself is specified while creating them. 

The connections and the statements should be closed via their `close(...)` functions. `commit(connection)`, `rollback(connection)` and `setAutoCommit(true|false)` do the obvious things.

###Metadata

Pass the `JResultSet` object from `executeQuery` to `getTableMetaData` to get an array of `(column_name, column_type)` tuples.

```julia
conn = DriverManager.getConnection("jdbc:derby:test/juliatest")
stmt = createStatement(conn)
rs = executeQuery(stmt, "select * from firsttable")
metadata = getTableMetaData(rs)
```

###DBAPI.jl Interface

[DBAPI.jl](https://github.com/JuliaDB/DBAPI.jl) is implemented in this package.  To connect:

```julia
conn = connect(JDBCInterface, "jdbc:mysql://127.0.0.1/",
               props=Dict("user" => "root", "passwd" => ""),
               connectorpath="/usr/share/java/mysql-connector-java.jar")
```

To disconnect:

```julia
close(conn)
```

To execute a query, we first need a cursor, then we run `execute!` on the cursor:

```julia
csr = cursor(conn)
execute!(csr, "insert into pi_table (pi_value) values (3.14);")
execute!(csr, "select * from my_table;")
```

To iterate over rows call `rows` on the cursor:

```julia
rs = rows(csr)
for row in rs
    # do stuff with row
end
```

To close the cursor call `close` on the cursor instance.

###Caveats
 * BLOB's are not yet supported. 
 * While a large part of the JDBC API has been wrapped, not everything is. Please file an issue if you find anything missing that you need. However, it is very easy to call the Java method directly using `JavaCall`. Please look at the `JDBC.jl` source for inspiration if you need to do that. 
 * Both Julia `DateTime` and Java `java.sql.Date` do not store any timezone information within them. I believe we are doing the right thing here, and everything should be consistent. However timezone is easy to get wrong, so please double check if your application depends on accurate times. 
 * There are many many different JDBC drivers in Java. This package needs testing with a wide variety of those. 

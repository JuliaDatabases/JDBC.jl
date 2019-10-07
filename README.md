# JDBC - Julia interface to Java JDBC database drivers

[![Build Status](https://travis-ci.org/JuliaDatabases/JDBC.jl.svg?branch=master)](https://travis-ci.org/JuliaDatabases/JDBC.jl)  [![Build status](https://ci.appveyor.com/api/projects/status/3m0pq27s24mkaduq?svg=true)](https://ci.appveyor.com/project/aviks/jdbc-jl)  [![JDBC](http://pkg.julialang.org/badges/JDBC_0.6.svg)](http://pkg.julialang.org/?pkg=JDBC)


This package enables the use of Java JDBC drivers to access databases from within Julia. It uses the [JavaCall.jl](https://github.com/aviks/JavaCall.jl) package to call into Java in order to use the JDBC drivers. 

The API provided by this package consists essentially of two components: a "direct" (i.e. minimally wrapped) interface directly to Java JDBC and a minimal
Julian interface with support for [Tables.jl](https://github.com/JuliaData/Tables.jl).

This package currently supports only Julia v0.6 and later.


### Initialisation and Destruction

To start it up, add the database driver jar file to the classpath, and then initialise the JVM. 

```julia
using JDBC
JDBC.usedriver("/home/me/derby/derby.jar")
JDBC.init() # or JavaCall.init()
 ```
The JVM remains in memory unless you explicitly destroy it.  This can be done with
```julia
JDBC.destroy() # or JavaCall.destroy()
```

### Low-Level Java Interface

As described above, this package provides functionality very similar to using a JDBC driver in Java. This allows you to write code very similar to how it would
look in Java.

```julia
conn = DriverManager.getConnection("jdbc:derby:test/juliatest")
stmt = createStatement(conn)
rs = executeQuery(stmt, "select * from firsttable")
for r in rs
     println(getInt(r, 1),  getString(r,"NAME"))
end
```

In JDBC, accessing the data frome a SQL call is done by iterating over a `ResultSet` instance. In Julia therefore, the `ResultSet` is a regular Julia iterator, and can be iterated in the usual fashion. 
To get each row as a Julia tuple, iterate over the result set using `JDBCRowIterator`.  Values in the tuple will be of Nullable type if they are declared to be nullable in the database.

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
#### Updates (Java Interface)

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

#### Metadata (Java Interface)

Pass the `JResultSet` object from `executeQuery` to `getTableMetaData` to get an array of `(column_name, column_type)` tuples.

```julia
conn = DriverManager.getConnection("jdbc:derby:test/juliatest")
stmt = createStatement(conn)
rs = executeQuery(stmt, "select * from firsttable")
metadata = getTableMetaData(rs)
```

### Julian Interface

This package also provides a more Julian interface for interacting with JDBC.  This involves creating `JDBC.Connection` and `JDBC.Cursor` objects to which query
strings can be passed
```julia
cnxn = JDBC.Connection("jdbc:derby:test/juliatest") # create connection
csr = cursor(cnxn) # create cursor from connection

# if you don't need access to the connection you can create the cursor directly
csr = cursor("jdbc:derby:test/juliatest")

# execute some SQL
execute!(csr, "insert into pi_table (pi_value) values (3.14);")
execute!(csr, "select * from my_table;")

# to iterate over rows
for row ∈ rows(csr)
    # do stuff with row
end

close(csr)  # closes Connection, can be called on Connection or Cursor
```

#### `Tables` Interface and Creating `DataFrame`s

JDBC includes a [Tables](https://github.com/JuliaData/Tables.jl) interface.  A Tables
`Source` object can be created from a `JDBC.Cursor` or a `JDBCRowIterator` simply by doing
e.g. `JDBC.Source(csr)`.  It can be useful for retrieving metadata with `Tables.schema`.

This is also useful for loading data from a database into another object that implements the Tables interface.  For this we
provide also the convenient `JDBC.load` function.

For example, you can do
```julia
src = JDBC.Source(csr)  # create a Source from a JDBC.Cursor
# here we load into a DataFrame, but can be any Data.Sink
df = JDBC.load(DataFrame, src)

# you can also load from the cursor directly
df = JDBC.load(DataFrame, csr)
```
Note that in the above we are assuming that a query was already executed.

### Absolute Quickest Way to Get DataBase Data into `DataFrame`

```julia
cnxn_str = "jdbc:derby:test/juliatest"  # for example
df = JDBC.load(DataFrame, cursor(cnxn_str), "select * from sometable")
```
Note again that this works not only for `DataFrame` but any `Data.Sink`.

There are a few more `JDBC.load` methods we haven't listed here, see `methods(JDBC.load)`.

### Caveats
 * BLOB's are not yet supported. 
 * While a large part of the JDBC API has been wrapped, not everything is. Please file an issue if you find anything missing that you need. However, it is very easy to call the Java method directly using `JavaCall`. Please look at the `JDBC.jl` source for inspiration if you need to do that. 
 * Both Julia `DateTime` and Java `java.sql.Date` do not store any timezone information within them. I believe we are doing the right thing here, and everything should be consistent. However timezone is easy to get wrong, so please double check if your application depends on accurate times. 
 * There are many many different JDBC drivers in Java. This package needs testing with a wide variety of those.

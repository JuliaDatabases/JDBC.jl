#This file is part of JDBC.jl. License is MIT.
module JDBC
using JavaCall
using Dates

export DriverManager, createStatement, prepareStatement, prepareCall, executeQuery, setFetchSize,
        getInt, getFloat, getString, getShort, getByte, getTime, getTimestamp, getDate,
        getBoolean, getNString, getURL, setInt, setFloat, setString, setShort, setByte, setBoolean,
        getMetaData, getColumnCount, getColumnType, getColumnName, executeUpdate, execute, commit,
        rollback, setAutoCommit, getResultSet


module DriverManager
    using JavaCall

    const JDriverManager = @jimport java.sql.DriverManager

    function getConnection(url::AbstractString)
        jcall(JDriverManager, "getConnection", @jimport(java.sql.Connection), (JString, ), url)
    end

    function getConnection(url::AbstractString, props::Dict)
        jcall(JDriverManager, "getConnection", @jimport(java.sql.Connection),
              (JString, @jimport(java.util.Properties)), url, props)
    end
end


const JResultSet = @jimport java.sql.ResultSet
const JResultSetMetaData = @jimport java.sql.ResultSetMetaData
const JStatement = @jimport java.sql.Statement
const JPreparedStatement = @jimport java.sql.PreparedStatement
const JCallableStatement = @jimport java.sql.CallableStatement
const JConnection = @jimport java.sql.Connection

const COLUMN_NO_NULLS = 0
const COLUMN_NULLABLE = 1
const COLUMN_NULLABLE_UNKNOWN = 2

init() = JavaCall.init()
destroy() = JavaCall.destroy()

"""
```
createStatement(connection::JConnection)
```
Initializes a Statement

### Args
* connection: The connection object

### Returns
The JStatement object
"""
createStatement(connection::JConnection) = jcall(connection, "createStatement", JStatement, (),)

"""
```
prepareStatement(connection::JConnection, query::AbstractString)
```
Prepares the Statement for the given query

### Args
* connection: The connection object
* query: The query string

### Returns
The JPreparedStatement object
"""
prepareStatement(connection::JConnection, query::AbstractString) = jcall(connection, "prepareStatement", JPreparedStatement, (JString,), query)

"""
```
prepareCall(connection::JConnection, query::AbstractString)
```
Prepares the Callable Statement for the given query

### Args
* connection: The connection object
* query: The query string

### Returns
The JCallableStatement object
"""
prepareCall(connection::JConnection, query::AbstractString) = jcall(connection, "prepareCall", JCallableStatement, (JString,), query)


"""
```
commit(connection::JConnection)
```
Commits the transaction

### Args
* connection: The connection object

### Returns
None
"""
commit(connection::JConnection) = jcall(connection, "commit", Nothing, ())


"""
```
rollback(connection::JConnection)
```
Rolls back the transactions.

### Args
* connection: The connection object

### Returns
None
"""
rollback(connection::JConnection) = jcall(connection, "rollback", Nothing, ())


"""
```
setAutoCommit(connection::JConnection, x::Bool)
```
Set the Auto Commit flag to either true or false. If set to false, commit has to be called explicitly

### Args
* connection: The connection object

### Returns
None
"""
setAutoCommit(connection::JConnection, x::Bool) = jcall(connection, "setAutoCommit", Nothing, (jboolean,), x)


"""
```
executeQuery(stmt::JStatement, query::AbstractString)
```
Executes the auery and returns the results as a JResultSet object.

### Args
* stmt: The Statement object
* query: The query to be executed

### Returns
The result set as a JResultSet object
"""
executeQuery(stmt::JStatement, query::AbstractString) = jcall(stmt, "executeQuery", JResultSet, (JString,), query)


"""
```
executeUpdate(stmt::JStatement, query::AbstractString)
```
Executes the update auery and returns the status of the execution of the query

### Args
* stmt: The Statement object
* query: The query to be executed

### Returns
An integer representing the status of the execution
"""
executeUpdate(stmt::JStatement, query::AbstractString) = jcall(stmt, "executeUpdate", jint, (JString,), query)


"""
```
execute(stmt::(Union{JPreparedStatement, JCallableStatement}))
```
Executes the auery based on the Prepared Statement or Callable Statement

### Args
* stmt: The Prepared Statement or the Callable Statement object

### Returns
A boolean indicating whether the execution was successful or not
"""
execute(stmt::Union{JPreparedStatement, JCallableStatement}) = jcall(stmt, "execute", jboolean, ())


"""
```
execute(stmt::JStatement, query::AbstractString)
```
Executes the auery based on JStatement or any of its sub-types

### Args
* stmt: The JStatement object or any of its sub-types
* query: The query to be executed

### Returns
A boolean indicating whether the execution was successful or not
"""
execute(stmt::JStatement, query::AbstractString) = jcall(stmt, "execute", jboolean, (JString,), query)


"""
```
executeQuery(stmt::Union{JPreparedStatement, JCallableStatement})
```
Executes the auery based on a JPreparedStatement object or a JCallableStatement object

### Args
* stmt: The JPreparedStatement object or JCallableStatement object

### Returns
The result set as a JResultSet object
"""
executeQuery(stmt::Union{JPreparedStatement, JCallableStatement}) = jcall(stmt, "executeQuery", JResultSet, ())


"""
```
executeUpdate(stmt::Union{JPreparedStatement, JCallableStatement})
```
Executes the update auery based on a JPreparedStatement object or a JCallableStatement object

### Args
* stmt: The JPreparedStatement object or JCallableStatement object

### Returns
An integer indicating the status of the execution of the query
"""
executeUpdate(stmt::Union{JPreparedStatement, JCallableStatement}) = jcall(stmt, "executeUpdate", jint, ())


"""
```
clearParameters(stmt::Union{JPreparedStatement, JCallableStatement})
```
Clears the currently held parameters in a JPreparedStatement object or a JCallableStatement object

### Args
* stmt: The JPreparedStatement object or JCallableStatement object

### Returns
None
"""
clearParameters(stmt::Union{JPreparedStatement, JCallableStatement}) = jcall(stmt, "clearParameters", Nothing, ())


"""
```
setFetchSize(stmt::Union{JStatement, JPreparedStatement, JCallableStatement }, x::Integer)
```
Sets the fetch size in a JStatement or a JPreparedStatement object or a JCallableStatement object. The number of records that are returned in subsequent query executions are determined by what is set here.

### Args
* stmt: The JPreparedStatement object or JCallableStatement object
* x: The number of records to be returned

### Returns
None
"""
setFetchSize(stmt::Union{JStatement, JPreparedStatement, JCallableStatement }, x::Integer) = jcall(stmt, "setFetchSize", Nothing, (jint,), x )


"""
```
getResultSet(stmt::JStatement)
```
Returns the result set based on the previous execution of the query based on a JStatement

### Args
* stmt: The JStatement object

### Returns
The JResultSet object.
"""
getResultSet(stmt::JStatement) = jcall(stmt, "getResultSet", JResultSet, ())

isdone(rs::JResultSet) = jcall(rs, "next", jboolean, ()) == 0

Base.iterate(rs::JResultSet, state=1) = isdone(rs) ? nothing : (rs, state)

Base.IteratorSize(::JResultSet) = Base.SizeUnknown()

for s in [("String", :JString),
          ("NString", :JString),
          ("Boolean", :jboolean),
          ("Short", :jshort),
          ("Int", :jint),
          ("Long", :jlong),
          ("Float", :jfloat),
          ("Double", :jdouble),
          ("Byte", :jbyte),
          ("URL", :(@jimport(java.net.URL))),
          ("BigDecimal", :(@jimport(java.math.BigDecimal)))]
        m = Symbol(string("get", s[1]))
        n = Symbol(string("set", s[1]))
        v = quote
            $m(rs::Union{JResultSet, JCallableStatement}, fld::AbstractString) = jcall(rs, $(string(m)), $(s[2]), (JString,), fld)
            $m(rs::Union{JResultSet, JCallableStatement}, fld::Integer) = jcall(rs, $(string(m)), $(s[2]), (jint,), fld)
            $n(stmt::Union{JPreparedStatement, JCallableStatement}, idx::Integer, v ) = jcall(stmt, $(string(n)), Nothing, (jint, $(s[2])), idx, v)
        end
        eval(v)
end

"""
```
getDate(rs::Union{JResultSet, JCallableStatement}, fld::AbstractString)
```
Returns the Date object based on the result set or a callable statement. The value is extracted based on the column name.

### Args
* stmt: The JResultSet or JCallableStatement object
* fld: The column name

### Returns
The Date object.
"""
getDate(rs::Union{JResultSet, JCallableStatement}, fld::AbstractString) = Date(convert(DateTime, jcall(rs, "getDate", @jimport(java.sql.Date), (JString,), fld)))


"""
```
getDate(rs::Union{JResultSet, JCallableStatement}, fld::Integer)
```
Returns the Date object based on the result set or a callable statement. The value is extracted based on the column number.

### Args
* stmt: The JResultSet or JCallableStatement object
* fld: The column number

### Returns
The Date object.
"""
getDate(rs::Union{JResultSet, JCallableStatement}, fld::Integer) = Date(convert(DateTime, jcall(rs, "getDate", @jimport(java.sql.Date), (jint,), fld)))


"""
```
getTimestamp(rs::Union{JResultSet, JCallableStatement}, fld::AbstractString)
```
Returns the Timestamp object based on the result set or a callable statement. The value is extracted based on the column name.

### Args
* stmt: The JResultSet or JCallableStatement object
* fld: The column name

### Returns
The Timestamp object.
"""
getTimestamp(rs::Union{JResultSet, JCallableStatement}, fld::AbstractString) = convert(DateTime, jcall(rs, "getTimestamp", @jimport(java.sql.Timestamp), (JString,), fld))


"""
```
getTimestamp(rs::@Union{JResultSet, JCallableStatement}, fld::Integer)
```
Returns the Timestamp object based on the result set or a callable statement. The value is extracted based on the column number.

### Args
* stmt: The JResultSet or JCallableStatement object
* fld: The column number

### Returns
The Timestamp object.
"""
getTimestamp(rs::Union{JResultSet, JCallableStatement}, fld::Integer) = convert(DateTime, jcall(rs, "getTimestamp", @jimport(java.sql.Timestamp), (jint,), fld))


"""
```
getTime(rs::Union{JResultSet, JCallableStatement}, fld::AbstractString)
```
Returns the Time object based on the result set or a callable statement. The value is extracted based on the column name.

### Args
* stmt: The JResultSet or JCallableStatement object
* fld: The column name

### Returns
The Time object.
"""
getTime(rs::Union{JResultSet, JCallableStatement}, fld::AbstractString) = convert(DateTime, jcall(rs, "getTime", @jimport(java.sql.Time), (JString,), fld))


"""
```
getTime(rs::Union{JResultSet, JCallableStatement}, fld::Integer)
```
Returns the Time object based on the result set or a callable statement. The value is extracted based on the column number.

### Args
* stmt: The JResultSet or JCallableStatement object
* fld: The column number

### Returns
The Time object.
"""
getTime(rs::Union{JResultSet, JCallableStatement}, fld::Integer) = convert(DateTime, jcall(rs, "getTime", @jimport(java.sql.Time), (jint,), fld))

Base.close(x::Union{JResultSet, JStatement, JPreparedStatement, JCallableStatement, JConnection}) = jcall(x, "close", Nothing, ())

wasNull(rs::JResultSet) = (jcall(rs, "wasNull", jboolean, ()) != 0)

"""
```
getMetaData(rs::JResultSet)
```
Returns information about the types and properties of the columns in the ResultSet object

### Args
* stmt: The JResultSet object

### Returns
The JResultSetMetaData object.
"""
getMetaData(rs::JResultSet) = jcall(rs, "getMetaData", JResultSetMetaData, ())


"""
```
absolute!(rs::JResultSet, row::Int)
```
Move the cursor to the specified row.

### Args
* rs: The JResultSet object.
* row: The row to move to.

### Returns
A boolean indicating success.
"""
absolute!(rs::JResultSet, row::Int) = jcall(rs, "absolute", jboolean, (jint,), row)


"""
```
beforeFirst!(rs::JResultSet)
```
Move the cursor to the front of the `JResultSet`, before the first row.

### Args
* rs: The JResultSet object.

### Returns
`nothing`
"""
beforeFirst!(rs::JResultSet) = jcall(rs, "beforeFirst", Nothing, ())


"""
```
getColumnCount(rsmd::JResultSetMetaData)
```
Returns the number of columns based on the JResultSetMetaData object

### Args
* rsmd: The JResultSetMetaData object

### Returns
The number of columns.
"""
getColumnCount(rsmd::JResultSetMetaData) = jcall(rsmd, "getColumnCount", jint, ())


"""
```
getColumnType(rsmd::JResultSetMetaData, col::Integer)
```
Returns the column's data type based on the JResultSetMetaData object and the column number

### Args
* rsmd: The JResultSetMetaData object
* col: The column number

### Returns
The column type as an integer
"""
getColumnType(rsmd::JResultSetMetaData, col::Integer) = jcall(rsmd, "getColumnType", jint, (jint,), col)


"""
```
getColumnName(rsmd::JResultSetMetaData, col::Integer)
```
Returns the column's name based on the JResultSetMetaData object and the column number

### Args
* rsmd: The JResultSetMetaData object
* col: The column number

### Returns
The column name
"""
getColumnName(rsmd::JResultSetMetaData, col::Integer) = jcall(rsmd, "getColumnName", JString, (jint,), col)

getColumnPrecision(rsmd::JResultSetMetaData, col::Integer) = jcall(rsmd, "getColumnPrecision", jint, (jint,), col)
getColumnScale(rsmd::JResultSetMetaData, col::Integer) = jcall(rsmd, "getColumnScale", jint, (jint,), col)


isNullable(rsmd::JResultSetMetaData, col::Integer) = jcall(rsmd, "isNullable", jint, (jint,), col)


function jdbc_get_method(coltype::Integer)
    return get_method_dict[coltype]
end

#Column Type Constants
global const JDBC_COLTYPE_ARRAY = 2003
global const JDBC_COLTYPE_BIGINT = -5
global const JDBC_COLTYPE_BINARY = -2
global const JDBC_COLTYPE_BIT = -7
global const JDBC_COLTYPE_BLOB = 2004
global const JDBC_COLTYPE_BOOLEAN = 16
global const JDBC_COLTYPE_CHAR = 1
global const JDBC_COLTYPE_CLOB = 2005
global const JDBC_COLTYPE_DATALINK = 70
global const JDBC_COLTYPE_DATE = 91
global const JDBC_COLTYPE_DECIMAL = 3
global const JDBC_COLTYPE_DISTINCT = 2001
global const JDBC_COLTYPE_DOUBLE = 8
global const JDBC_COLTYPE_FLOAT = 6
global const JDBC_COLTYPE_INTEGER = 4
global const JDBC_COLTYPE_JAVA_OBJECT = 2000
global const JDBC_COLTYPE_LONGNVARCHAR = -16
global const JDBC_COLTYPE_LONGVARBINARY = -4
global const JDBC_COLTYPE_LONGVARCHAR = -1
global const JDBC_COLTYPE_NCHAR = -15
global const JDBC_COLTYPE_NCLOB = 2011
global const JDBC_COLTYPE_NULL = 0
global const JDBC_COLTYPE_NUMERIC = 2
global const JDBC_COLTYPE_NVARCHAR = -9
global const JDBC_COLTYPE_OTHER = 1111
global const JDBC_COLTYPE_REAL = 7
global const JDBC_COLTYPE_REF = 2006
global const JDBC_COLTYPE_ROWID = -8
global const JDBC_COLTYPE_SMALLINT = 5
global const JDBC_COLTYPE_SQLXML = 2009
global const JDBC_COLTYPE_STRUCT = 2002
global const JDBC_COLTYPE_TIME = 92
global const JDBC_COLTYPE_TIMESTAMP = 93
global const JDBC_COLTYPE_TINYINT = -6
global const JDBC_COLTYPE_VARBINARY = -3
global const JDBC_COLTYPE_VARCHAR = 12
global const JDBC_COLTYPE_TIMESTAMP_LOCAL_TIMEZONE = -102

#Map column types to their respective get methods
global const get_method_dict = Dict(
        # JDBC_COLTYPE_ARRAY => 2003,
        JDBC_COLTYPE_BIGINT => getLong,
        # JDBC_COLTYPE_BINARY => -2,
        JDBC_COLTYPE_BIT => getBoolean,
        # JDBC_COLTYPE_BLOB => 2004,
        JDBC_COLTYPE_BOOLEAN => getBoolean,
        JDBC_COLTYPE_CHAR => getString,
        # JDBC_COLTYPE_CLOB => 2005,
        # JDBC_COLTYPE_DATALINK => 70,
        JDBC_COLTYPE_DATE => getDate,
        JDBC_COLTYPE_DECIMAL => getFloat,
        # JDBC_COLTYPE_DISTINCT => 2001,
        JDBC_COLTYPE_DOUBLE => getDouble,
        JDBC_COLTYPE_FLOAT => getFloat,
        JDBC_COLTYPE_INTEGER => getLong,
        # JDBC_COLTYPE_JAVA_OBJECT => 2000,
        JDBC_COLTYPE_LONGNVARCHAR => getNString,
        # JDBC_COLTYPE_LONGVARBINARY => -4,
        JDBC_COLTYPE_LONGVARCHAR => getString,
        JDBC_COLTYPE_NCHAR => getNString,
        # JDBC_COLTYPE_NCLOB => 2011,
        # JDBC_COLTYPE_NULL => 0,
        JDBC_COLTYPE_NUMERIC => getDouble,
        JDBC_COLTYPE_NVARCHAR => getNString,
        # JDBC_COLTYPE_OTHER => 1111,
        JDBC_COLTYPE_REAL => getFloat,
        # JDBC_COLTYPE_REF => 2006,
        JDBC_COLTYPE_ROWID => getLong,
        JDBC_COLTYPE_SMALLINT => getShort,
        # JDBC_COLTYPE_SQLXML => 2009,
        # JDBC_COLTYPE_STRUCT => 2002,
        JDBC_COLTYPE_TIME => getTime,
        JDBC_COLTYPE_TIMESTAMP => getTimestamp,
        JDBC_COLTYPE_TINYINT => getByte,
        # JDBC_COLTYPE_VARBINARY => -3,
        JDBC_COLTYPE_VARCHAR => getString,
        # JDBC_COLTYPE_TIMESTAMP_LOCAL_TIMEZONE => -102
        JDBC_COLTYPE_TIMESTAMP_LOCAL_TIMEZONE => getTimestamp,
        )

"""
Get the metadata (column name and type) for each column of the table in the
 result set `rs`.

Returns an array of (column name, column type) tuples.
"""
function getTableMetaData(rs::JResultSet)
    rsmd = getMetaData(rs)
    cols = getColumnCount(rsmd)
    mdarr = Array{Any}(undef, cols)
    for i = 1:cols
        mdarr[i] = (getColumnName(rsmd, i), getColumnType(rsmd, i))
    end
    return mdarr
end

"""
Iterator to get rows of tables as array of tuples.
"""
mutable struct JDBCRowIterator
    rs::JResultSet
    ncols::Int
    get_methods::Vector{Function}
    isnullable::Vector{Int}

    function JDBCRowIterator(rs::JResultSet)
        rsmd = getMetaData(rs)
        ncols = getColumnCount(rsmd)
        get_methods = Array{Function}(undef, ncols)
        isnullable = Array{Int}(undef, ncols)
        for c in 1:ncols
            get_methods[c] = jdbc_get_method(getColumnType(rsmd, c))
            isnullable[c] = isNullable(rsmd, c)
        end

        new(rs, ncols, get_methods, isnullable)
    end
end

function Base.iterate(iter::JDBCRowIterator, state=1)
    isdone(iter.rs) && (return nothing)
    row = Array{Any}(undef, iter.ncols)
    for c ∈ 1:iter.ncols
        val = iter.get_methods[c](iter.rs, c)
        if wasNull(iter.rs)
            row[c] = missing
        elseif iter.isnullable[c] == COLUMN_NULLABLE || iter.isnullable[c] == COLUMN_NULLABLE_UNKNOWN
            row[c] = val
        else
            row[c] = val
        end
    end
    tuple(row...), state
end

Base.IteratorSize(::JDBCRowIterator) = Base.SizeUnknown()
Base.IteratorEltype(::JDBCRowIterator) = Base.EltypeUnknown()

export getTableMetaData, JDBCRowIterator


include("interface.jl")
include("datastreams.jl")


end # module

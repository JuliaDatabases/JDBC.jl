#This file is part of JDBC.jl. License is MIT.
module JDBC
using JavaCall
using Compat
using Requires

if VERSION < v"0.4-"
    using Dates
else
    using Base.Dates
end

export DriverManager, createStatement, executeQuery, getInt, getFloat, getString, getShort, getByte, getTime, getTimeStamp, getDate, 
        getBoolean, getNString, getURL, getMetaData, getColumnCount, getColumnType, getColumnName

module DriverManager
    using JavaCall
    JDriverManager = @jimport java.sql.DriverManager
    function getConnection(url::ASCIIString)
        jcall(JDriverManager, "getConnection", @jimport(java.sql.Connection), (JString, ), url)
    end

    function getConnection(url::ASCIIString, props::Dict)
        jcall(JDriverManager, "getConnection", @jimport(java.sql.Connection), (JString,  @jimport(java.util.Properties)), url, props)
    end

end



JResultSet = @jimport java.sql.ResultSet
JResultSetMetaData = @jimport java.sql.ResultSetMetaData
JStatement= @jimport java.sql.Statement


init() = JavaCall.init()

createStatement(connection::@jimport(java.sql.Connection)) = jcall(connection, "createStatement", @jimport(java.sql.Statement), (),)

executeQuery(stmt::@jimport(java.sql.Statement), query::String) = jcall(stmt, "executeQuery", JResultSet, (JString,), query)

Base.start(rs::JResultSet) = true
Base.next(rs::JResultSet, state) = rs, state
Base.done(rs::JResultSet, state)  = !bool(jcall(rs, "next", jboolean, ()))


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
        m = symbol(string("get", s[1]))
        v = quote 
            $m(rs::JResultSet, fld::String) = jcall(rs, $(string(m)), $(s[2]), (JString,), fld)
            $m(rs::JResultSet, fld::Integer) = jcall(rs, $(string(m)), $(s[2]), (jint,), fld)
        end
        eval(v)
end

getDate(rs::JResultSet, fld::String) = Date(convert(DateTime, jcall(rs, "getDate", @jimport(java.sql.Date), (JString,), fld)))
getDate(rs::JResultSet, fld::Integer) = Date(convert(DateTime, jcall(rs, "getDate", @jimport(java.sql.Date), (jint,), fld)))
getTimeStamp(rs::JResultSet, fld::String) = convert(DateTime, jcall(rs, "getTimeStamp", @jimport(java.sql.TimeStamp), (JString,), fld))
getTimeStamp(rs::JResultSet, fld::Integer) = convert(DateTime, jcall(rs, "getTimeStamp", @jimport(java.sql.TimeStamp), (jint,), fld))
getTime(rs::JResultSet, fld::String) = convert(DateTime, jcall(rs, "getTime", @jimport(java.sql.Time), (JString,), fld))
getTime(rs::JResultSet, fld::Integer) = convert(DateTime, jcall(rs, "getTime", @jimport(java.sql.Time), (jint,), fld))


Base.close(rs::JResultSet) = jcall(rs, "close", Void, ())
Base.close(stmt::@jimport(java.sql.Statement)) = jcall(stmt, "close", Void, ())
wasNull(rs::JResultSet) = bool(jcall(rs, "wasNull", jboolean, ()))

getMetaData(rs::JResultSet) = jcall(rs, "getMetaData", JResultSetMetaData, ())
getColumnCount(rsmd::JResultSetMetaData) = jcall(rsmd, "getColumnCount", jint, ())
getColumnType(rsmd::JResultSetMetaData, col::Integer) = jcall(rsmd, "getColumnType", jint, (jint,), col)
getColumnName(rsmd::JResultSetMetaData, col::Integer) = jcall(rsmd, "getColumnName", JString, (jint,), col)

@require DataFrames begin
using DataFrames
function DataFrames.readtable(rs::JResultSet) 
    rsmd = getMetaData(rs)
    cols = getColumnCount(rsmd)
    columns = Array(Any, cols)
    missings = Array(Any, cols)
    cnames = Array(Symbol, cols)
    get_methods = Array(Function, cols)
    for c in 1:cols
        columns[c] = Array(Any, 0)
        missings[c] = Array(Bool, 0)
        cnames[c] = DataFrames.makeidentifier(getColumnName(rsmd, c))
        get_methods[c] = jdbc_get_method(getColumnType(rsmd, c))
    end 
    for r in rs
        for c in 1:cols
            tp = getColumnType(rsmd, c)
            push!(columns[c], apply(get_methods[c], (rs, c)))
            if wasNull(rs)
                push!(missings[c], true)
            else
                push!(missings[c], false)
            end
        end       
    end

    dcolumns = Array(Any, cols)
    
    for c in 1:cols
        dcolumns[c] = DataArrays.DataArray(columns[c], missings[c])  
    end 
    return DataFrame(dcolumns, cnames)
end
end #@require 

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

#Map column types to their respective get methods
global const get_method_dict = @compat Dict( 
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
        JDBC_COLTYPE_NUMERIC => getInt,
        JDBC_COLTYPE_NVARCHAR => getNString,
        # JDBC_COLTYPE_OTHER => 1111,
        JDBC_COLTYPE_REAL => getFloat,
        # JDBC_COLTYPE_REF => 2006,
        JDBC_COLTYPE_ROWID => getInt,
        JDBC_COLTYPE_SMALLINT => getShort,
        # JDBC_COLTYPE_SQLXML => 2009,
        # JDBC_COLTYPE_STRUCT => 2002,
        JDBC_COLTYPE_TIME => getTime,
        JDBC_COLTYPE_TIMESTAMP => getTimeStamp,
        JDBC_COLTYPE_TINYINT => getByte,
        # JDBC_COLTYPE_VARBINARY => -3,
        JDBC_COLTYPE_VARCHAR => getString
        )

end # module

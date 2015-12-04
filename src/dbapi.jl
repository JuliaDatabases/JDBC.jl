using DBAPI
using JavaCall

abstract JDBCInterface <: DatabaseInterface

type JDBCConnection <: DatabaseConnection{JDBCInterface}
    conn::Union{JConnection, Void}
end

type JDBCError <: DatabaseError{JDBCInterface}
    msg::AbstractString
end

function Base.showerror(io::IO, e::JDBCError)
    print(io, JDBCError, ": " * e.msg)
end

type JDBCCursor <: DatabaseCursor{JDBCInterface}
    conn::JDBCConnection
    stmt::Union{JStatement, Void}
    rs::Union{JResultSet, Void}
end

function JDBCCursor(conn)
    isopen(conn) || throw(JDBCError("Attempting to create cursor with a null connection"))
    stmt = createStatement(conn.conn)
    JDBCCursor(conn, stmt, nothing)
end

export JDBCInterface, JDBCError, JDBCConnection, JDBCCursor

import DBAPI: show, connect, close, isopen, commit, rollback, cursor,
              connection, execute!, rows

"""
Open a JDBC Connection to the specified `host`.  The username and password can be optionally passed
 as a Dictionary `props` of the form `Dict("user" => "username", "passwd" => "password")`.
  The JDBC connector location can be optionally passed as `connectorpath`, if it is not
 added to the java class path.

Returns a `JDBCConnection` instance.
"""
function connect(::Type{JDBCInterface}, host; props=Dict{}, connectorpath="")
    if !JavaCall.isloaded()
        connectorpath != "" && JavaCall.addClassPath(connectorpath)
        JDBC.init()
    end
    if props != Dict{}
        conn = DriverManager.getConnection(host, props)
    else
        conn = DriverManager.getConnection(host)
    end
    return JDBCConnection(conn)
end

"""
Closes the JDBCConnection `conn`.  Throws a `JDBCError` if connection is null.

Returns `nothing`.
"""
function close(conn::JDBCConnection)
    isopen(conn) || throw(JDBCError("Cannot close null connection."))
    close(conn.conn)
    conn.conn = nothing
    return nothing
end

"""
Close the JDBCCursor `csr`.  Throws a `JDBCError` if cursor is not initialized.

Returns `nothing`.
"""
function close(csr::JDBCCursor)
    csr.stmt == nothing && throw(JDBCError("Cannot close uninitialized cursor."))
    csr.rs == nothing || begin; close(csr.rs); csr.rs = nothing; end
    close(csr.stmt)
    csr.stmt = nothing
    return nothing
end

"""
Returns a boolean indicating whether connection `conn` is open.
"""
isopen(conn::JDBCConnection) = conn.conn != nothing

"""
Commit any pending transaction to the database.  Throws a `JDBCError` if connection is null.

Returns `nothing`.
"""
function commit(conn::JDBCConnection)
    isopen(conn) || throw(JDBCError("Commit called on null connection."))
    commit(conn.conn)
    return nothing
end

"""
Roll back to the start of any pending transaction.  Throws a `JDBCError` if connection is null.

Returns `nothing`.
"""
function rollback(conn::JDBCConnection)
    isopen(conn) || throw(JDBCError("Rollback called on null connection."))
    rollback(conn.conn)
    return nothing
end

"""
Create a new database cursor.

Returns a `JDBCCursor` instance.
"""
cursor(conn::JDBCConnection) = JDBCCursor(conn)

"""
Return the corresponding connection for a given cursor.
"""
connection(csr::JDBCCursor) = csr.conn

"""
Run a query on a database.

The results of the query are not returned by this function but are accessible
through the cursor.

`parameters` can be any iterable of positional parameters, or of some
T<:Associative for keyword/named parameters.

Throws a `JDBCError` if query caused an error, cursor is not initialized or
 connection is null.

Returns `nothing`.
"""
function execute!(csr::JDBCCursor, qry::DatabaseQuery, parameters=())
    isopen(connection(csr)) || throw(JDBCError("Cannot execute with null connection."))
    csr.stmt == nothing && throw(JDBCError("Execute called on uninitialized cursor."))
    exectype = execute(csr.stmt, qry.query)
    try
        JavaCall.geterror()
    catch err
        throw(JDBCError(err.msg))
    end
    if exectype == 1  # if this is a statement that returned a result set.
        csr.rs = getResultSet(csr.stmt)
    else
        csr.rs = nothing
    end
    return nothing
end

"""
Create a row iterator.

This method returns an instance of an iterator type which returns one row
on each iteration. Each row returnes a Tuple{...}.

Throws a `JDBCError` if `execute!` was not called on the cursor or connection is null.

Returns a `JDBCRowIterator` instance.
"""
function rows(csr::JDBCCursor)
    isopen(connection(csr)) || throw(JDBCError("Cannot create iterator with null connection."))
    csr.rs == nothing && throw(JDBCError("Cannot create iterator with null result set.  Please call execute! on the cursor first."))
    return JDBCRowIterator(csr.rs)
end

export connect, close, isopen, commit, rollback, cursor,
       connection, execute!, rows

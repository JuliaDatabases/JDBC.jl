module JDBC
using JavaCall

export DriverManager, createStatement, executeQuery, getInt, getFloat, getString

module DriverManager
    using JavaCall
    function getConnection(url::ASCIIString)
        dm = @jimport java.sql.DriverManager
        jcall(dm, "getConnection", @jimport(java.sql.Connection), (JString, ), url)
    end
end

createStatement(connection::@jimport(java.sql.Connection)) = jcall(connection, "createStatement", @jimport(java.sql.Statement), (),)

executeQuery(stmt::@jimport(java.sql.Statement), query::String) = jcall(stmt, "executeQuery", @jimport(java.sql.ResultSet), (JString,), query)

Base.start(rs::@jimport(java.sql.ResultSet)) = true
Base.next(rs::@jimport(java.sql.ResultSet), state) = rs, state
Base.done(rs::@jimport(java.sql.ResultSet), state)  = !bool(jcall(rs, "next", jboolean, ()))


for s in [("String", :JString),
            ("Int", :jint),
            ("Long", :jlong),
            ("Float", :jfloat),
            ("Double", :jdouble)]
        m = symbol(string("get", s[1]))
        v = quote 
            $m(rs::@jimport(java.sql.ResultSet), fld::String) = jcall(rs, $(string(m)), $(s[2]), (JString,), fld)
            $m(rs::@jimport(java.sql.ResultSet), fld::Integer) = jcall(rs, $(string(m)), $(s[2]), (jint,), fld)
        end
        eval(v)
end

end # module

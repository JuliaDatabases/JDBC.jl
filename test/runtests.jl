using JavaCall
using JDBC
using Base.Test

JavaCall.addClassPath(joinpath(Pkg.dir("JDBC"), "test", "derby.jar"))
JavaCall.init()
conn = DriverManager.getConnection("jdbc:derby:test/juliatest")
stmt = createStatement(conn)
rs = executeQuery(stmt, "select * from firsttable")

for r in rs
    println(getInt(r, 1)," ", getString(r,"NAME"))
end

JavaCall.destroy()

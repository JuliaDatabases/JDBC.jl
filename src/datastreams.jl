using DataStreams

const column_types = Dict(
                          JDBC_COLTYPE_ARRAY=>Array,
                          JDBC_COLTYPE_BIGINT=>Int64,
                          JDBC_COLTYPE_BIT=>Bool,
                          JDBC_COLTYPE_BOOLEAN=>Bool,
                          JDBC_COLTYPE_CHAR=>String,
                          JDBC_COLTYPE_DATE=>Date,
                          JDBC_COLTYPE_DECIMAL=>Float64,
                          JDBC_COLTYPE_DOUBLE=>Float64,
                          JDBC_COLTYPE_FLOAT=>Float32,
                          JDBC_COLTYPE_INTEGER=>Int32,
                          JDBC_COLTYPE_LONGNVARCHAR=>String,
                          JDBC_COLTYPE_LONGVARCHAR=>String,
                          JDBC_COLTYPE_NCHAR=>String,
                          JDBC_COLTYPE_NUMERIC=>Float64,
                          JDBC_COLTYPE_NVARCHAR=>String,
                          JDBC_COLTYPE_REAL=>Float64,
                          JDBC_COLTYPE_ROWID=>Int64,
                          JDBC_COLTYPE_SMALLINT=>Int16,
                          JDBC_COLTYPE_TIME=>DateTime,
                          JDBC_COLTYPE_TIMESTAMP=>DateTime,
                          JDBC_COLTYPE_TINYINT=>Int8,
                          JDBC_COLTYPE_VARCHAR=>String
                         )


usedriver(str::AbstractString) = JavaCall.addClassPath(str)


struct Source
    rs::JResultSet
    md::JResultSetMetaData
end
Source(rs::JResultSet) = Source(rs, getMetaData(rs))
Source(stmt::JStatement, query::AbstractString) = Source(executeQuery(stmt, query))
Source(rowit::JDBCRowIterator) = Source(rowit.rs)
function Source(csr::Cursor)
    if csr.rs == nothing
        throw(ArgumentError("A cursor must contain a valid JResultSet to construct a Source."))
    else
        Source(csr.rs)
    end
end

# these methods directly access the underlying JResultSet and are used in Schema constructor
function coltype(s::Source, col::Int)
    dtype = get(column_types, getColumnType(s.md, col), Any)
    if isNullable(s.md, col) == COLUMN_NO_NULLS
        dtype
    else
        Union{dtype, Missing}
    end
end
colname(s::Source, col::Int) = getColumnName(s.md, col)
ncols(s::Source) = getColumnCount(s.md)

coltypes(s::Source) = Type[coltype(s, i) for i ∈ 1:ncols(s)]
colnames(s::Source) = String[colname(s, i) for i ∈ 1:ncols(s)]

# WARNING: this does not seem to actually work
Data.reset!(s::Source) = beforeFirst!(s.rs)

Data.isdone(s::Source, row::Int, col::Int)  = isdone(s.rs)

Data.schema(s::Source) = Data.Schema(coltypes(s), colnames(s), missing)

Data.accesspattern(s::Source) = Data.Sequential

Data.streamtype(::Type{Source}, ::Type{Data.Field}) = true
Data.streamtype(::Type{Source}, ::Type{Data.Column}) = false

# TODO currently jdbc_get_method is very inefficient
pullfield(s::Source, col::Int) = jdbc_get_method(getColumnType(s.md, col))(s.rs, col)

# does not store current row number as a persistent state
function Data.streamfrom(s::Source, ::Type{Data.Field}, ::Type{T}, row::Int, col::Int) where T
    convert(T, pullfield(s, col))::T
end
function Data.streamfrom(s::Source, ::Type{Data.Field}, ::Type{Union{T, Missing}},
                         row::Int, col::Int) where T
    o = pullfield(s, col)
    if wasNull(s.rs)
        return missing
    end
    convert(T, o)::T
end

load(::Type{T}, s::Source) where {T} = Data.close!(Data.stream!(s, T))
load(::Type{T}, rs::JResultSet) where {T} = load(T, Source(rs))
load(::Type{T}, stmt::JStatement, query::AbstractString) where {T} = load(T, Source(stmt, query))
load(::Type{T}, csr::Union{JDBC.Cursor,JDBCRowIterator}) where {T} = load(T, Source(csr))
function load(::Type{T}, csr::Cursor, q::AbstractString) where T
    execute!(csr, q)
    load(T, csr)
end


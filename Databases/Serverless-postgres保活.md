
# supabase-postgres保活

创建保活的表

```
create table public.ping_test (
  id bigint generated always as identity primary key,
  created_at timestamptz default now()
);

-- 让匿名用户（anon key）可以读取
grant select on public.ping_test to anon;
```

检查保活的表

```
select table_schema, table_name 
from information_schema.tables 
where table_schema='public';
```

保活信息

```
curl -X GET "https://dhylzscchtcknmtpuxwf.supabase.co/rest/v1/ping_test?select=id" -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRoeWx6c2NjaHRja25tdHB1eHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzMDUyNzIsImV4cCI6MjA4MDg4MTI3Mn0.iomEpDuXGixtr0QCoc1ekm_7nszkByzhxaMB-Abl5SM"
```

执行上面的命令行之后，会返回一个空数组 [] ,表示反馈正常。

# Aiven-postgres保活

创建表并插入一条数据

```
create table ping_test (
  id bigint primary key generated always as identity,
  created_at timestamp with time zone default now()
);

insert into ping_test default values;
```

使用uptime kuma保活 ，在uptime kuma中输入查询语句

```
SELECT id FROM ping_test LIMIT 1;
```

如果不使用uptime kuma,而使用linux保活的话，就需要安装psql

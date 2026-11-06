-- Bronze Layer: Ingesting Data
create or refresh streaming table cs_bronze_sales
(
    constraint data_loaded expect (orderid is not null),
    constraint data_loaded2 expect (productid is not null),
    constraint data_loaded3 expect (quantity is not null)
)

comment 'Data is loaded only when the orderid is not empty'

as select *, 
    _metadata.file_path as source_file,
    current_timestamp as injected_at
from stream read_files("/Volumes/retail_sales_sdp/default/retail_sales_volume", 
format => 'csv',
header => "true");
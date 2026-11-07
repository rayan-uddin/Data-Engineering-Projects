create or refresh streaming table hospital_billings_sdp.default.hospital_billings_bronze
as
select *, 
    _metadata.file_path as source_file,
    current_timestamp as injected_at
from stream read_files("/Volumes/hospital_billings_sdp/default/hospital_billings_volume", 
format => 'csv',
header => "true");
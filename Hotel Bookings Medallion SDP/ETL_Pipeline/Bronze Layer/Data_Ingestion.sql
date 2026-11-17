create or refresh streaming table hotel_bookings_sdp.default.hotel_bookings_bronze 
as
select *, 
    _metadata.file_path as source_file,
    current_timestamp as injected_at
from stream read_files("/Volumes/hotel_bookings_sdp/default/hotel_bookings_volume", 
format => 'csv',
header => "true");
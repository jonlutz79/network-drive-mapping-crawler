select * from [User];

/* Unique UNC Paths */
select * from UNCPath;

select * from DriveMapping;

/* Drive Mappings By User */
select m.DriveMappingID, u.Username, m.DriveLetter, p.UNCPath, m.IsActive from DriveMapping m
inner join UNCPath p
on m.UNCPathID = p.UNCPathID
inner join [User] u
on m.UserID = u.UserID
order by u.Username

function mapped_channels = NIDAQ_Channel_Interface(channels)
% Maps NIDAQ channels to MATLAB arrays
% Takes in the channels from NIDAQ input in a list form
channel_dict = [
    1 52;
    2 17;
    3 49;
    4 47;
    5 19;
    6 51;
    7 16;
    8 48;
    9 11;
    10 10;
    11 43;
    12 42;
    13 41; 
    14 6;
    15 5;
    16 38;
    17 37;
    18 3;
    19 45;
    20 46;
    21 2;
    22 40;
    23 1;
    24 39;];

mapped_channels = zeros(1, length(channels));

for ii = 1:length(channels)
    indices = find(channel_dict(:,2) == channels(ii));
    mapped_channels(ii) = channel_dict(indices,1);
end

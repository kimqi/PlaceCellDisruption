%% Detect if in TTL Zone and Trigger
function [] = zone_detect(c, ax, ht, ttl_zone, theta, center)

global pos
global pos_opti
global time_opti
global time_mat
global pos_lin
global trig_on
global save_loc
global zone_sum
global srate
global D4value
global on_minutes

delta_pos = capture_pos(c); % get position
pos_curr = pos(end,:);
pos_s = cart_to_track(pos_curr, theta, center);
pos_lin = [pos_lin; pos_s];

% Turn TTL off if rat's position has not changed at all (most likely
% optitrack can't find it) OR if rat is chilling within zone for greater
% than zone_thresh seconds
zone_thresh = 15;
if all(delta_pos == 0) || zone_sum >= zone_thresh*srate %sqrt(sum(delta_pos.^2)) < 0.05 %
    trigger_off(ax, ht, pos_s)
    trig_on = [trig_on; 0];
    if (pos_s <= ttl_zone(1)) || (pos_s >= ttl_zone(2))
        zone_sum = 0; % reset time in trigger zone to 0
    end
else % Logic to trigger is the rat is in the appropriate zone below
    if (pos_s > ttl_zone(1)) && (pos_s < ttl_zone(2)) %pos_curr(3) > ttl_zone(1) && pos_curr(3) < ttl_zone(2)
        trigger_on(ax, ht, pos_s)
        trig_on = [trig_on; 1];
        zone_sum = zone_sum + 1; % Increment time tracked in trigger zone
        
    % Send D2 to 0V if outside of zone and currently at 5V
    elseif (pos_s <= ttl_zone(1)) || (pos_s >= ttl_zone(2)) %(pos_curr(3) <= ttl_zone(1)) || (pos_curr(3) >= ttl_zone(2))
        trigger_off(ax, ht, pos_s)
        trig_on = [trig_on; 0];
        zone_sum = 0; % reset time in trigger zone to 0
    end
end
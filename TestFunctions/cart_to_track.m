function [s] = cart_to_track(pos_curr, ndir_vec, center)
% Calculate vector from start point to current position
v = pos_curr - center;
s = dot(v, ndir_vec);
track_point = center + t * ndir_vec;

end
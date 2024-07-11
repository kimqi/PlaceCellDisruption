function [] = trigger_on(ax, ht, pos_curr)

global do_LEDs
global LEDs_id
global pos_lin
global pos_opti
global trig_on
global hl
global hlcartx
global hlcartz
global hlcarto

if length(pos_curr) == 3
    pos_use = pos_curr(3);
else
    pos_use = pos_curr;
end

if isobject(do_LEDs)
    % Need code for having signal in initial off state
    do_LEDs.Signal_Off_NI(LEDs_id);
    do_LEDs.toggleNI(LEDs_id, 0.01);
end

% What does this do
text_append = ['-' num2str(pos_use, '%0.2g')];

% Update window for LED ON.
colormap(ax,[0 1 0])
ht.String = ['ON' text_append];
hl(1).YData = pos_lin;
hl(2).XData = find(trig_on == 1);
hl(2).YData = pos_lin(trig_on == 1);

nframes = size(pos_opti,1);
hlcartx(1).YData = pos_opti(:,1);
hlcartx(2).XData = nframes;
hlcartx(2).YData = pos_opti(end,1);

hlcartz(1).YData = pos_opti(:,3);
hlcartz(2).XData = nframes;
hlcartz(2).YData = pos_opti(end,3);

hlcarto(1).XData = pos_opti(:,1);
hlcarto(1).YData = pos_opti(:,3);
hlcarto(2).XData = pos_opti(end,1);
hlcarto(2).YData = pos_opti(end,3);

end
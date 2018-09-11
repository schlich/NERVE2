function y = bound(x,bl,bu)
%BOUND return bounded value clipped between bl and bu
y=min(max(x,bl),bu);
end
function DoTrial2(app)
%DoTrial2 Calls DoTrial twice for Pretrial and Trial sequence.
%   This function can be modified together with DoTrial to create additional
% tasks with custom sequences (e.g., target sphere then target torus).
% DO NOT USE!!! Not ready.

DoTrial(app, 'torus');
DoTrial(app, 'sphere');
end


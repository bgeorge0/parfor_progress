function percent = parfor_progress(N)
%PARFOR_PROGRESS Progress monitor (progress bar) that works with parfor.
%   PARFOR_PROGRESS works by creating a file called parfor_progress.txt in
%   your working directory, and then keeping track of the parfor loop's
%   progress within that file. This workaround is necessary because parfor
%   workers cannot communicate with one another so there is no simple way
%   to know which iterations have finished and which haven't.
%
%   PARFOR_PROGRESS(N) initializes the progress monitor for a set of N
%   upcoming calculations.
%a
%   PARFOR_PROGRESS updates the progress inside your parfor loop and
%   displays an updated progress bar.
%
%   PARFOR_PROGRESS(0) deletes parfor_progress.txt and finalizes progress
%   bar.
%
%   To suppress output from any of these functions, just ask for a return
%   variable from the function calls, like PERCENT = PARFOR_PROGRESS which
%   returns the percentage of completion.
%
%   Example:
%
%      N = 100;
%      parfor_progress(N);
%      parfor i=1:N
%         pause(rand); % Replace with real code
%         parfor_progress;
%      end
%      parfor_progress(0);
%
%   See also PARFOR.

% By Jeremy Scheff - jdscheff@gmail.com - http://www.jeremyscheff.com/

narginchk(0, 1);

if nargin < 1
    N = -1;
end

percent = 0;
w = 50; % Width of progress bar
tn = now; % Time now

if N > 0
    
    % If no GCP, create it now. This will stop the message being displayed
    % after the parfor display has started
    if isempty(gcp('nocreate'))
        gcp;
    end
    
    f = fopen('parfor_progress.txt', 'w');
    if f<0
        error('Do you have write permissions for %s?', pwd);
    end
    fprintf(f, '%5.8f\n%5.8f\n', N, tn); % Save N and t at the top of progress.txt
    fclose(f);
    
    time_fmt = 'HH:MM:SS';
    t_start = datestr(now, time_fmt);
    t_now = datestr(tn, time_fmt);
    
    %waitbar(0, 'Progress');
    if nargout == 0
        disp(['  0%[>', repmat(' ', 1, w), ']', ' ', t_start, ' -> ', t_now, ' -> ', time_fmt]);
    end
elseif N == 0
    f = fopen('parfor_progress.txt', 'r');
    progress = fscanf(f, '%f');
    fclose(f);
    try
        delete('parfor_progress.txt');
    catch
    end
    percent = 100;
    
    time_fmt = 'HH:MM:SS';
    t_start = datestr(progress(2), time_fmt);
    t_now = datestr(tn, time_fmt);
    t_end = datestr(now, time_fmt);
    
    if nargout == 0
        disp([repmat(char(8), 1, (w+9+33)), newline, '100%[', repmat('=', 1, w+1), ']', ' ', t_start, ' -> ', t_now, ' -> ', t_end]);
    end
    %h = findall(0,'Tag','TMWWaitbar');
    %close(h);
else
    try
        % Much quicker to just try this and catch the error
        % It was taking ~33% of the time on this if statement
        %if ~exist('parfor_progress.txt', 'file')
        %error('parfor_progress.txt not found. Run PARFOR_PROGRESS(N) before PARFOR_PROGRESS to initialize parfor_progress.txt.');
        %end
        
        f = fopen('parfor_progress.txt', 'a');
        fprintf(f, '%5.8f\n', tn);
        fclose(f);
        
        f = fopen('parfor_progress.txt', 'r');
        progress = fscanf(f, '%f');
        fclose(f);
        percent = (length(progress)-2)/progress(1)*100;
        
        % Caclaulated elased time
        t1 = progress(2);
        time_fmt = 'HH:MM:SS';
        t_start = datestr(progress(2), time_fmt);
        t_now = datestr(tn, time_fmt);
        t_estend = datestr((((tn-t1)/percent) * 100) + t1, time_fmt);
        
        if nargout == 0
            perc = sprintf('%3.0f%%', percent); % 4 characters wide, percentage
            % This is probably quicker as sprintf, but it is currnely an
            % insignificant amout of time compared to the file operations,
            % so may as well keep it as it is.
            disp([repmat(char(8), 1, w+9+33), newline, perc, '[', repmat('=', 1, round(percent*w/100)), '>', repmat(' ', 1, w - round(percent*w/100)), ']', ' ', t_start, ' -> ', t_now, ' -> ', t_estend]);
        end
        %h = findall(0,'Tag','TMWWaitbar');
        %waitbar(percent/100, h);
    catch
        error('parfor_progress.txt not found. Run PARFOR_PROGRESS(N) before PARFOR_PROGRESS to initialize parfor_progress.txt.');
    end
end
end

if rak_only
    
    % Get audio data from RAK
    this_audio = double(rak_cam.readAudio());
    if isempty(this_audio)
        disp('no audio data received')
    else
        % Get first 1000 samples
        x = this_audio(1:1000);
    end

    % Get spectrum
    n = length(x);
    fs = 8000;
    dt = 1/fs;
    t = (0:n-1)/fs;
    y = fft(x);
    pw = (abs(y).^2)/n;
    f = (0:n-1)*(fs/n);
    
    % Convert to Z scores
    if ~isempty(pw)
        if ax <= 10
            these_vals = (pw - mean(pw)) / std(pw);
            if length(these_vals) == 1000
                pw2(ax, :) = these_vals;
            end
            ax = ax + 1;
        else
            ax = 1;
        end
        pw3 = mean(pw2);
        pw = pw3;
        [max_amp, j] = max(pw(1:500)); % Is this the right range?
        max_freq = f(j);    
    else
        max_amp = 0;
        max_freq = 0;
    end
    
    this_start = length(audioMat);
    audioMat = [audioMat this_audio];
    audioAmp = [audioAmp max_amp];
    audioFreq = [audioFreq max_freq];
    this_end = length(audioMat);
    audio_max_freq = max_freq;
%     disp(horzcat('audio max freq = ', num2str(max_freq), ', amp = ', num2str(max_amp), ', start = ', num2str(this_start), ', end = ', num2str(this_end)))

end

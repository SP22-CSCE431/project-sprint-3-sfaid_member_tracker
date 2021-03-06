# frozen_string_literal: true

# AttendancesController
class AttendancesController < ApplicationController
  before_action :set_attendance, only: %i[show edit update destroy]

  # GET /attendances or /attendances.json
  def index
    # by default, only grab current user's attendance
    @user = grab_user
    return redirect_to '/', notice: 'Invalid user session. Please try logging in again.' if @user.nil?

    @attendances = Attendance.where(user_id: @user.id)
    @attendances = Attendance.all if grab_permissions[:view_all_attendances]
    @perms = grab_permissions
    return redirect_to '/', notice: 'Invalid user session. Please try logging in again.' if @perms.nil?
  end

  # GET /attendances/1 or /attendances/1.json
  def show
    redirect_to '/', notice: 'Attempted to access disabled route.'
  end

  # GET /attendances/new
  def new
    @attendance = Attendance.new
  end

  # GET /attendances/1/edit
  def edit
    @attendance_id = params[:id]
    @attendance = Attendance.where(id: @attendance_id).first

    return redirect_to '/' if @attendance.nil?

    redirect_to '/', notice: 'Insufficient permissions.' unless grab_permissions[:view_all_attendances] || @attendance.attend_time_start.nil? || @attendance.attend_time_end.nil?
  end

  # POST /attendances or /attendances.json
  def create
    @attendance = Attendance.new(attendance_params)

    @user = grab_user
    return redirect_to '/', notice: 'Invalid user session. Please try logging in again.' if @user.nil?

    if attendance_params[:event_id].empty? || attendance_params[:event_id].nil?
      flash[:alert] = 'Must attend an event'
      return render 'new'
    end

    if @attendance.attend_time_start.nil? || @attendance.attend_time_end.nil?
      flash[:alert] = 'Must set attendance times'
      return render 'new'
    end

    @event = Event.where(id: @attendance.event_id).first
    if !(@attendance.attend_time_start.to_time.strftime('%H:%M:%S') >= @event.event_time_start.to_time.strftime('%H:%M:%S') && @attendance.attend_time_end.to_time.strftime('%H:%M:%S') <= @event.event_time_end.to_time.strftime('%H:%M:%S'))
      flash[:alert] = 'Attendance time must be within bounds of event time'
      return render 'new'
    elsif @attendance.attend_time_start.to_time.strftime('%H:%M:%S') > @attendance.attend_time_end.to_time.strftime('%H:%M:%S')
      flash[:alert] = 'Attendance time must start before ending'
      return render 'new'
    end

    # case: if attendance record already exists, update instead of creating new
    @attn = Attendance.where(event_id: attendance_params[:event_id], user_id: @user.id)
    unless @attn.empty?
      @attn = @attn.first
      respond_to do |format|
        if @attn.update(attend_time_start: attendance_params[:attend_time_start], attend_time_end: attendance_params[:attend_time_end], plans_to_attend: attendance_params[:plans_to_attend])
          format.html { return redirect_to attendances_path, notice: 'Attendance was successfully updated.' }
          format.json { return render :index, status: :ok, location: @attendance }
        else
          format.html { return render :create, status: :unprocessable_entity }
          format.json { return render json: @attendance.errors, status: :unprocessable_entity }
        end
      end
    end

    @user = grab_user
    return redirect_to '/', notice: 'Invalid user session. Please try logging in again.' if @user.nil?

    @attendance.update(user_id: @user.id)

    respond_to do |format|
      if @attendance.save
        format.html { redirect_to attendances_path, notice: 'Attendance was successfully created.' }
        format.json { render :index, status: :created, location: @attendance }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @attendance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /attendances/1 or /attendances/1.json
  def update
    @attendance_id = params[:id]
    @attendance = Attendance.where(id: @attendance_id).first
    @event = Event.where(id: @attendance.event_id).first

    return redirect_to '/' if @attendance.nil?

    unless grab_permissions[:view_all_attendances] || @attendance.attend_time_start.nil? || @attendance.attend_time_end.nil?
      return redirect_to '/',
                         notice: 'Insufficient permissions.'
    end

    if attendance_params[:attend_time_start].empty? || attendance_params[:attend_time_end].empty?
      flash[:alert] = 'Must set attendance times'
      return render 'edit'
    end

    if !(attendance_params[:attend_time_start].to_time.strftime('%H:%M:%S') >= @event.event_time_start.to_time.strftime('%H:%M:%S') && attendance_params[:attend_time_end].to_time.strftime('%H:%M:%S') <= @event.event_time_end.to_time.strftime('%H:%M:%S'))
      flash[:alert] = 'Attendance time must be within bounds of event time'
      return render 'edit'
    elsif attendance_params[:attend_time_start].to_time.strftime('%H:%M:%S') > attendance_params[:attend_time_end].to_time.strftime('%H:%M:%S')
      flash[:alert] = 'Attendance time must start before ending'
      return render 'edit'
    end

    respond_to do |format|
      if @attendance.update(attendance_params)
        format.html { redirect_to attendances_path, notice: 'Attendance was successfully updated.' }
        format.json { render :index, status: :ok, location: @attendance }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @attendance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attendances/1 or /attendances/1.json
  def destroy
    @attendance.destroy

    respond_to do |format|
      format.html { redirect_to attendances_url, notice: 'Attendance was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_attendance
    @attendance = Attendance.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def attendance_params
    params.require(:attendance).permit(:event_id, :user_id, :attend_time_start, :attend_time_end, :plans_to_attend)
  end
end

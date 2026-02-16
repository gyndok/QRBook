import SwiftUI

struct CalendarFormView: View {
    @Binding var data: CalendarEventData

    var body: some View {
        Section("Calendar Event") {
            TextField("Event Title", text: $data.title)
            TextField("Location", text: $data.location)
            Toggle("All Day", isOn: $data.allDay)
            DatePicker("Start Date", selection: $data.startDate, displayedComponents: .date)
            if !data.allDay {
                DatePicker("Start Time", selection: $data.startTime, displayedComponents: .hourAndMinute)
            }
            DatePicker("End Date", selection: $data.endDate, displayedComponents: .date)
            if !data.allDay {
                DatePicker("End Time", selection: $data.endTime, displayedComponents: .hourAndMinute)
            }
            TextField("Description", text: $data.eventDescription, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}

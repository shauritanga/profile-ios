import SwiftUI

struct ProfileHeader:View {
    var body: some View{
        VStack {
            HStack{
                Text("Profile")
                    .font(.headline)
                Spacer()
                Label {
                    Text("12")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                } icon: {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white)
                        .frame(width: 60, height: 30)
                        .overlay(HStack{
                            Text("12")
                            Image(systemName: "flame.fill")
                            .foregroundColor(.red)                            }
                        )
                }
                .labelStyle(.iconOnly)
                
            }
            Image("me")
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 150)
                .clipShape(Circle())
            Text("Athanas Shauritanga")
                .font(.system(size: 30))
                .foregroundColor(.primary)
            Text("shauritangaathanas@gmail.com")
                .foregroundColor(.secondary)
            
            
        }
        .padding()
       
    }
}

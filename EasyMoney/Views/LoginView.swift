import SwiftUI

struct LoginView: View {
    private enum FormField: Hashable {
        case email
        case password
    }

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: FormField?

    var body: some View {
        ZStack {
            // background
            Backgrounds.gradient2
                .ignoresSafeArea()

            // main VStack
            VStack(spacing: 0) {
                
                // header
                HeaderView(
                    title: "EasyMoney",
                    subtitle: "Sign in to manage your money",
                    icon: "wallet.bifold.fill"
                )
                .padding(.bottom, 30)

                // form
                VStack(alignment: .leading, spacing: 6) {
                    
                    // email
                    Text("Email:")
                        .font(.system(size: 10))
                        .foregroundStyle(.black)

                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        TextField("you@mail.com", text: $email)
                            .textFieldStyle(.plain)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                    }
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(.white.opacity(0.86))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                focusedField == .email ? Color(hex: "#16865A") : .clear,
                                lineWidth: 2
                            )
                    }

                    // password
                    Text("Password:")
                        .font(.system(size: 10))
                        .foregroundStyle(.black)
                        .padding(.top, 8)

                    HStack(spacing: 10) {
                        Image(systemName: "lock")
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        Group {
                            if isPasswordVisible {
                                TextField("Enter your password", text: $password)
                            } else {
                                SecureField("Enter your password", text: $password)
                            }
                        }
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .password)

                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                                .frame(width: 30, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                    }
                    .font(.system(size: 14))
                    .padding(.leading, 14)
                    .padding(.trailing, 4)
                    .frame(height: 50)
                    .background(.white.opacity(0.86))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                focusedField == .password ? Color(hex: "#16865A") : .clear,
                                lineWidth: 2
                            )
                    }
                } // form
                .padding(.horizontal, 25)

                // login button
                Button(action: {}) {
                    Text("Sign in with email")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 170, height: 34)
                        .background(Color(hex: "#16865A"))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.top, 13)

                // sign up button

                Spacer()
            } // main VStack
            .padding(.top, 50)
        } // ZStack
    }
}

#Preview {
    LoginView()
}

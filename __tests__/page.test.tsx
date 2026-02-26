import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import Home from "@/app/page";

describe("Home page", () => {
  it("renders the Hello World heading", () => {
    render(<Home />);
    expect(screen.getByRole("heading", { name: /hello, world!/i })).toBeInTheDocument();
  });

  it("displays an initial counter value of 0", () => {
    render(<Home />);
    expect(screen.getByText("0")).toBeInTheDocument();
  });

  it("increments the counter when + is clicked", async () => {
    const user = userEvent.setup();
    render(<Home />);
    await user.click(screen.getByRole("button", { name: /increase/i }));
    expect(screen.getByText("1")).toBeInTheDocument();
  });

  it("decrements the counter when − is clicked", async () => {
    const user = userEvent.setup();
    render(<Home />);
    await user.click(screen.getByRole("button", { name: /decrease/i }));
    expect(screen.getByText("-1")).toBeInTheDocument();
  });
});

import { render, screen, act } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import Home from "@/app/page";

const mockFetch = (responses: { count: number }[]) => {
  let call = 0;
  global.fetch = jest.fn(() =>
    Promise.resolve({
      json: () => Promise.resolve(responses[call++] ?? responses[responses.length - 1]),
    } as Response)
  );
};

afterEach(() => {
  jest.restoreAllMocks();
});

describe("Home page", () => {
  it("renders the Hello World heading", async () => {
    mockFetch([{ count: 0 }]);
    await act(async () => render(<Home />));
    expect(screen.getByRole("heading", { name: /hello, world!/i })).toBeInTheDocument();
  });

  it("shows a placeholder before the counter loads", () => {
    mockFetch([{ count: 0 }]);
    render(<Home />);
    expect(screen.getByText("—")).toBeInTheDocument();
  });

  it("displays the counter value returned from the API on mount", async () => {
    mockFetch([{ count: 5 }]);
    await act(async () => render(<Home />));
    expect(screen.getByText("5")).toBeInTheDocument();
  });

  it("updates the counter when + is clicked", async () => {
    mockFetch([{ count: 5 }, { count: 6 }]);
    const user = userEvent.setup();
    await act(async () => render(<Home />));
    await user.click(screen.getByRole("button", { name: /increase/i }));
    expect(screen.getByText("6")).toBeInTheDocument();
  });
});
